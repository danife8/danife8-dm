# frozen_string_literal: true

module MediaMixes
  # MediaMixes::MeetsMinimum to evaluate minimun column
  class MeetsMinimum
    def initialize(campaign_channel_id:, target_strategy_id:, budget_size:, amount:, amount_per_day:, channel_type: :primary)
      @campaign_channel_id = campaign_channel_id
      @target_strategy_id = target_strategy_id
      @budget_size = budget_size
      @amount = amount
      @amount_per_day = amount_per_day
      @channel_type = channel_type
    end

    def call
      general_minimum? && daily_minimum?
    end

    protected

    attr_accessor :campaign_channel_id, :target_strategy_id, :budget_size, :amount, :amount_per_day, :channel_type

    def daily_minimum?
      daily_min = DailyBudgetMinimum.where(campaign_channel_id:, target_strategy_id:).first || DailyBudgetMinimumDefault.first

      amount_per_day >= daily_min.send(budget_size)
    end

    def general_minimum?
      amount >= line_item_minimum.send(budget_size)
    end

    def line_item_minimum
      return GeneralLineItemMinimum.first if channel_type == :primary

      SecondaryChannelLineItemMinimum.find_by(campaign_channel_id:)
    end
  end
end
