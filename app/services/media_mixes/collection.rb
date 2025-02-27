# frozen_string_literal: true

module MediaMixes
  # MediaMixes::Collection to get engine collection with re calculations
  class Collection
    def initialize(media_brief)
      @media_brief = media_brief
      @results = []
    end

    def call
      initial

      if results.last[:engine][:channel_strategies][:secondary_channels].any?
        step1(results.last[:engine].deep_dup) # STEP 1: Secondary channels reallocation
      end

      if results.last[:engine][:channel_strategies][:primary_channels].any?
        step2(results.last[:engine].deep_dup) # STEP 2: Primary channels reallocation
      end

      final

      {
        campaign_objective_id: media_brief.campaign_objective.id,
        campaign_objective: {id: media_brief.campaign_objective.id, label: media_brief.campaign_objective.label},
        campaign_initiative: {id: media_brief.campaign_initiative.id, label: media_brief.campaign_initiative.label},
        campaign_initiative_id: media_brief.campaign_initiative.id,
        budget: media_brief.campaign_budget,
        budget_size: results.first[:engine][:budget_size],
        flight_days: results.first[:engine][:flight_days],
        channel_strategies: final_results
      }
    end

    protected

    attr_accessor :media_brief, :results

    def final_results
      results.map.with_index do |result, index|
        {title: result[:title], position: index}.merge(result[:engine][:channel_strategies])
      end
    end

    def initial
      @results << {
        title: "Initial output based on Admin Settings:",
        engine: Engine.new(media_brief, virtual_percentages).call
      }
    end

    def step1(engine)
      reallocation = Reallocate::SecondaryChannel.new(engine, virtual_percentages).call
      return unless reallocation

      title = if reallocation[:channel_strategies][:secondary_channels].any?
        "Re-allocation Step 1: Reallocate in secondary channel"
      else
        "Re-allocation Step 1: Remove Secondary Channel and Reallocate to Primary Channels"
      end

      @results << {title:, engine: reallocation}
    end

    def step2(engine)
      service = Reallocate::PrimaryChannel.new(engine, virtual_percentages)
      reallocation = service.call
      return unless reallocation

      @results += service.logger
    end

    def final
      @results << {title: "Final Output", engine: results.last[:engine]}
    end

    def virtual_percentages
      @virtual_percentages ||= OpenStruct.new(
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
