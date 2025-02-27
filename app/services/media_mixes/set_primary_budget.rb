# frozen_string_literal: true

module MediaMixes
  class SetPrimaryBudget
    def initialize(primary_channels, flight_days, budget, budget_size, virtual_percentages = nil)
      @primary_channels = primary_channels
      @flight_days = flight_days
      @budget = budget
      @budget_size = budget_size
      @virtual_percentages = virtual_percentages
    end

    def call
      set_channel_budget
      set_strategy_budgets

      primary_channels
    end

    protected

    attr_accessor :primary_channels, :flight_days, :budget, :budget_size, :virtual_percentages

    def set_channel_budget
      primary_channels.each_with_index do |primary_channel, index|
        platform_budget = percentages.send("primary_channel#{index + 1}")
        platform_amt = budget.to_f * (platform_budget.to_f / 100.0)

        primary_channel.merge!(platform_budget:, platform_amt:)
      end
    end

    def set_strategy_budgets
      primary_channels.each_with_index do |primary_channel, primary_index|
        # Set default values
        primary_channel[:target_strategies].each { |ts| ts.merge!(budget: 0.00, amt: 0.00, amt_pd: 0.00, meets_min: nil) }

        primary_channel[:target_strategies].select { |ts| ts[:target_strategy][:label] != "Retargeting" }.each_with_index do |target_strategy, index|
          budget = percentages.send("primary_channel#{primary_index + 1}_target_strategy#{index + 1}")
          amt = (primary_channel[:platform_amt].to_f * (budget.to_f / 100.00)).floor(2)
          amt_pd = amt / flight_days.to_f

          meets_min = MeetsMinimum.new(
            campaign_channel_id: primary_channel[:campaign_channel][:id],
            target_strategy_id: target_strategy[:target_strategy][:id],
            budget_size:,
            amount: amt,
            amount_per_day: amt_pd
          ).call

          target_strategy.merge!(budget:, amt:, amt_pd:, meets_min:)
        end
      end
    end

    def percentages
      @percentages ||= virtual_percentages || BudgetPercentageDefault.first
    end
  end
end
