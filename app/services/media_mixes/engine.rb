# frozen_string_literal: true

module MediaMixes
  class Engine
    def initialize(media_brief, budget_percentages = nil)
      @media_brief = media_brief
      @budget_percentages = budget_percentages || virtual_percentages
    end

    def call
      normalize_channels_percentages

      # Calculate meets min and budgets
      add_primary_budget
      add_secondary_budget
      normalize_target_strategies_percentages

      # Re calculate meets min and budgets
      add_primary_budget
      add_secondary_budget

      clean_channels_without_budget

      {
        campaign_objective_id: media_brief.campaign_objective.id,
        campaign_objective: {id: media_brief.campaign_objective.id, label: media_brief.campaign_objective.label},
        campaign_initiative_id: media_brief.campaign_initiative.id,
        campaign_initiative: {id: media_brief.campaign_initiative.id, label: media_brief.campaign_initiative.label},
        budget: media_brief.campaign_budget,
        budget_size:,
        flight_days:,
        channel_strategies:
      }
    end

    protected

    attr_accessor :media_brief, :budget_percentages

    def normalize_channels_percentages
      total_percentage = 100

      channels = [
        {
          percentage: budget_percentages.primary_channel1,
          key: :primary_channel1,
          channel: {key: :primary_channels, position: 0}
        },
        {
          percentage: budget_percentages.primary_channel2,
          key: :primary_channel2,
          channel: {key: :primary_channels, position: 1}
        },
        {
          percentage: budget_percentages.secondary_channel1,
          key: :secondary_channel1,
          channel: {key: :secondary_channels, position: 0}
        },
        {
          percentage: budget_percentages.secondary_channel2,
          key: :secondary_channel2,
          channel: {key: :secondary_channels, position: 1}
        },
        {
          percentage: budget_percentages.secondary_channel3,
          key: :secondary_channel3,
          channel: {key: :secondary_channels, position: 2}
        }
      ].select do |channel_percentage|
        channel_percentage[:percentage] > 0 &&
          channel_strategies.send(:[], channel_percentage[:channel][:key]).send(:[], channel_percentage[:channel][:position])&.try(:[], :target_strategies)&.any?
      end

      channels.each do |channel_percentage|
        total_percentage -= channel_percentage[:percentage]
      end

      return if total_percentage <= 0

      reallocate = total_percentage.to_f / channels.size.to_f

      channels.each do |channel_percentage|
        budget_percentages.send(:"#{channel_percentage[:key]}=", channel_percentage[:percentage] + reallocate)
      end
    end

    def normalize_target_strategies_percentages
      channels = []

      2.times do |n|
        extra_position = 0
        strategies = []
        5.times do |n2|
          target_strategies = channel_strategies[:primary_channels][n].try(:[], :target_strategies)
          target_strategy = target_strategies.try(:[], n2 + extra_position)
          label = target_strategy.try(:[], :target_strategy).try(:[], :label)
          key = :"primary_channel#{n + 1}_target_strategy#{n2 + 1}"

          unless label
            budget_percentages.send(:"#{key}=", 0) # Reset percentage
            next
          end

          extra_position += 1 if label == "Retargeting"
          next if budget_percentages.send(key) <= 0

          target_strategy = target_strategies.try(:[], n2 + extra_position)
          strategies << {
            percentage: budget_percentages.send(key),
            key:,
            strategy: n2 + extra_position,
            meets_min: target_strategy.try(:[], :meets_min),
            label: target_strategy.try(:[], :target_strategy).try(:[], :label)
          }
        end

        channels << {strategies:}
      end

      channels.each do |channel|
        total_percentage = 100

        channel[:strategies].each do |strategy_percentage|
          total_percentage -= strategy_percentage[:percentage]
        end

        next if total_percentage <= 0

        strategies_with_false_meets_min = channel[:strategies].select { |st| !st[:meets_min] }
        strategies = strategies_with_false_meets_min.any? ? strategies_with_false_meets_min : channel[:strategies]

        reallocate = total_percentage.to_f / strategies.size.to_f

        strategies.each do |strategy_percentage|
          budget_percentages.send(:"#{strategy_percentage[:key]}=", strategy_percentage[:percentage] + reallocate)
        end
      end
    end

    def flight_days
      @flight_days ||= (media_brief.campaign_ends_on - media_brief.campaign_starts_on + 1).to_f
    end

    def channel_strategies
      @channel_strategies ||= Channel.new(
        media_brief,
        budget_percentages.primary_channel1_include_retargeting,
        budget_percentages.primary_channel2_include_retargeting
      ).call
    end

    def add_primary_budget
      SetPrimaryBudget.new(channel_strategies[:primary_channels], flight_days, media_brief.campaign_budget, budget_size, budget_percentages).call
    end

    def add_secondary_budget
      SetSecondaryBudget.new(channel_strategies[:secondary_channels], flight_days, media_brief.campaign_budget, budget_size, budget_percentages).call
    end

    def budget_size
      @budget_size ||= BudgetSize.first.evaluate(media_brief.campaign_budget / flight_days.to_f)
    end

    def clean_channels_without_budget
      channel_strategies[:secondary_channels].reject! do |channel|
        channel[:platform_budget].zero? || channel[:target_strategies].blank?
      end

      channel_strategies[:primary_channels].each do |channel|
        channel[:target_strategies].reject! do |strategy|
          !strategy[:meets_min].nil? && strategy[:budget].zero?
        end
      end
    end

    def virtual_percentages
      OpenStruct.new(
        find_budget_percentage.attributes.except("id")
      )
    end

    def find_budget_percentage
      BudgetPercentage.by_campaign_objective_id(media_brief.campaign_objective_id)
        .by_campaign_initiative_id(media_brief.campaign_initiative_id)
        .by_industry_target(media_brief.industry_target).first || BudgetPercentageDefault.first
    end
  end
end
