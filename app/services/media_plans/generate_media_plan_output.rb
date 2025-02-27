# frozen_string_literal: true

module MediaPlans
  class GenerateMediaPlanOutput
    def initialize(media_plan)
      @media_plan = media_plan
    end

    attr_reader :media_plan

    def call
      unless media_plan.media_mix.has_media_output?
        Rails.logger.info("Media Plan Output for Media Plan ##{media_plan.id} could not be generated because: Media Mix ##{media_plan.media_mix.id} has no Media Output")
        return {error: true, errors: ["The Media Mix has no Media Output."]}
      end

      version = MediaPlanOutput.where(media_plan:).count + 1

      media_plan.update(media_plan_output_version: version)
      media_plan.create_media_plan_output(media_plan_output_params.merge(version:))

      return {error: true, errors: media_plan.media_plan_output.errors.full_messages} unless media_plan.media_plan_output.persisted?

      {error: false, errors: []}
    end

    protected

    def media_plan_output_params
      {
        media_plan_output_rows_attributes:
      }
    end

    def media_plan_output_rows_attributes
      global_index = 0
      rows = []

      channels.each do |channel|
        channel.target_strategies.each do |strategy|
          mrt = strategy.master_relationship

          impressions = if mrt.cpm.nil? || mrt.cpm.zero?
            0.00
          else
            (media_plan.media_brief.campaign_budget / mrt.cpm) * 1000
          end

          rows << {
            master_relationship_id: mrt.id,
            campaign_channel_id: channel.campaign_channel.id,
            media_platform_id: strategy.media_platform.id,
            target_strategy_id: strategy.target_strategy.id,
            target_id: strategy.target.id,
            ad_format_id: strategy.ad_format.id,
            amt: strategy.amt,
            impressions:,
            position: global_index
          }

          global_index += 1
        end
      end

      rows
    end

    def channels
      @channels ||= get_channels
    end

    def get_channels
      final_output = media_plan.media_mix.media_output.channel_strategies.last

      [final_output.primary_channels, final_output.secondary_channels].compact.flatten
    end
  end
end
