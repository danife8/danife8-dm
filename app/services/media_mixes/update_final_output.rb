module MediaMixes
  class UpdateFinalOutput
    def initialize(media_mix, final_output, params)
      @media_mix = media_mix
      @final_output = final_output
      @params = params.deep_dup
    end

    attr_reader :media_mix, :final_output, :params

    def call
      validate_and_save_final_output

      {error: nil}
    rescue Exceptions::FinalOutputError => e
      Rails.logger.error(e)

      {error: e.message, attempted_params: params}
    rescue => e
      Rails.logger.error(e)

      {error: "Something went wrong.", attempted_params: params}
    end

    private

    def validate_and_save_final_output
      MediaOutputChannelStrategy.transaction do
        validate_budget!
        validate_channels
      end

      final_output.update!(params)
    end

    def validate_budget!
      original_budget = media_mix.media_output.budget
      new_budget = new_amts

      if new_budget != original_budget
        raise Exceptions::FinalOutputBudgetExceededError, "Budget must equal #{ActiveSupport::NumberHelper.number_to_currency(original_budget)}."
      end
    end

    def new_amts
      sum_channel_amts(params[:primary_channels_attributes]) +
        sum_channel_amts(params[:secondary_channels_attributes])
    end

    def sum_channel_amts(channel_attributes)
      channel_attributes&.values&.sum do |channel_attr|
        channel_attr[:target_strategies_attributes]&.values&.sum { |strategy| strategy[:amt].to_f }
      end || 0.0
    end

    def validate_channels
      [:primary_channels_attributes, :secondary_channels_attributes].each do |channel_type|
        params[channel_type]&.each do |_, channel_attrs|
          validate_target_strategy(channel_attrs)
        end
      end
    end

    def validate_target_strategy(channel_attrs)
      campaign_channel = MediaOutputChannel.find(channel_attrs[:id])
      channel_attrs[:target_strategies_attributes]&.each do |_, target_attrs|
        is_retargeting = MediaOutputTargetStrategy.find(target_attrs[:id]).target_strategy.try(:label) == "Retargeting"
        next if is_retargeting || target_attrs["_destroy"] == "1"
        validate_target_strategy_meets_min!(target_attrs, campaign_channel)
      end
    end

    def validate_target_strategy_meets_min!(target_attrs, campaign_channel)
      amt = target_attrs[:amt].to_f
      amt_pd = amt / media_mix.media_output.flight_days.to_f
      budget = calculate_budget(amt, campaign_channel.platform_amt.to_f)
      target_strategy = MediaOutputTargetStrategy.find(target_attrs[:id])

      meets_min = MeetsMinimum.new(
        campaign_channel_id: campaign_channel.campaign_channel_id,
        target_strategy_id: target_strategy.target_strategy_id,
        budget_size:,
        amount: amt,
        amount_per_day: amt_pd
      ).call

      updated_attrs = target_attrs.except(:_destroy).merge(budget:, amt:, amt_pd:, meets_min:)

      # Update the params with the attempted values
      update_params(target_attrs[:id], updated_attrs)

      if meets_min
        target_strategy.update!(updated_attrs)
      else
        raise Exceptions::FinalOutputMeetsMinimumError, "The modified budget minimum does not match the default values minimums."
      end
    end

    def calculate_budget(amt, platform_amt)
      return 0.00 if platform_amt.zero?
      (amt * 100.00) / platform_amt
    end

    def update_params(target_strategy_id, updated_attrs)
      params[:primary_channels_attributes].each do |_index, channel_attrs|
        channel_attrs[:target_strategies_attributes]&.each do |_index, target_attrs|
          if target_attrs[:id].to_s == target_strategy_id.to_s
            target_attrs.merge!(updated_attrs.except(:id))
          end
        end
      end
      if params[:secondary_channels_attributes].present?
        params[:secondary_channels_attributes].each do |_index, channel_attrs|
          channel_attrs[:target_strategies_attributes]&.each do |_index, target_attrs|
            if target_attrs[:id].to_s == target_strategy_id.to_s
              target_attrs.merge!(updated_attrs.except(:id))
            end
          end
        end
      end
    end

    def budget_size
      @budget_size ||= BudgetSize.first.evaluate(media_mix.media_brief.campaign_budget)
    end
  end
end
