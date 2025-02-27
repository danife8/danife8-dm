# frozen_string_literal: true

module MediaMixes
  class SetSecondaryBudget
    def initialize(secondary_channels, flight_days, budget, budget_size, virtual_percentages = nil)
      @secondary_channels = secondary_channels
      @flight_days = flight_days
      @budget = budget
      @budget_size = budget_size
      @virtual_percentages = virtual_percentages
    end

    def call
      set_channel_budget
      set_strategy_budgets

      secondary_channels
    end

    protected

    attr_accessor :secondary_channels, :flight_days, :budget, :budget_size, :virtual_percentages

    def set_channel_budget
      secondary_channels.each_with_index do |secondary_channel, index|
        secondary_channel.merge!(platform_budget: percentages.send("secondary_channel#{index + 1}"), platform_amt: 0.00)
      end
    end

    def set_strategy_budgets
      secondary_channels.each_with_index do |secondary_channel, primary_index|
        # Set default values
        target_strategy = secondary_channel[:target_strategies].first
        next unless target_strategy

        target_strategy.merge!(amt: 0.00, amt_pd: 0.00, meets_min: nil)
        next if target_strategy[:target_strategy][:label] == "Retargeting"

        amt = (budget.to_f * (secondary_channel[:platform_budget].to_f / 100.00)).floor(2)
        amt_pd = amt / flight_days.to_f

        meets_min = MeetsMinimum.new(
          campaign_channel_id: secondary_channel[:campaign_channel][:id],
          target_strategy_id: target_strategy[:target_strategy][:id],
          budget_size:,
          amount: amt,
          amount_per_day: amt_pd,
          channel_type: :secondary
        ).call

        target_strategy.merge!(amt:, amt_pd:, meets_min:)
      end
    end

    def percentages
      @percentages ||= virtual_percentages || BudgetPercentageDefault.first
    end
  end
end
