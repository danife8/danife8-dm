# frozen_string_literal: true

module MediaMixes
  class Channel
    def initialize(media_brief, primary_channel1_retargeting = true, primary_channel2_retargeting = true)
      @media_brief = media_brief
      @data = {
        primary_channels: [],
        secondary_channels: []
      }
      @primary_channel1_retargeting = primary_channel1_retargeting
      @primary_channel2_retargeting = primary_channel2_retargeting
    end

    def call
      add_primary_channels
      add_secondary_channels

      data
    end

    protected

    attr_accessor :media_brief, :data, :primary_channel1_retargeting, :primary_channel2_retargeting

    def add_primary_channels
      return unless media_brief.primary_channel
      return unless channels.any?

      @data[:primary_channels] += channels.shift(2).map.with_index do |channel, index|
        include_retargeting = index.zero? ? primary_channel1_retargeting : primary_channel2_retargeting

        {
          title: "Primary channel #{index + 1}",
          campaign_channel_id: channel[0].id,
          campaign_channel: {id: channel[0].id, label: channel[0].label},
          target_strategies: sort_if_neccessary(channel[1], include_retargeting)
        }
      end
    end

    def add_secondary_channels
      return unless media_brief.secondary_channel
      return unless channels.any?

      @data[:secondary_channels] += channels.shift(3).map.with_index do |channel, index|
        {
          title: "Secondary channel #{index + 1}",
          campaign_channel_id: channel[0].id,
          campaign_channel: {id: channel[0].id, label: channel[0].label},
          target_strategies: sort_if_neccessary(channel[1]).take(1)
        }
      end
    end

    # @param master_relationships [Array<MasterRelationship>] master relationships associated with campaign channel
    # @param include_retargeting [TrueClass,FalseClass]
    def sort_if_neccessary(master_relationships, include_retargeting = true)
      strategies = if include_retargeting
        master_relationships.take(5)
      else
        master_relationships.select { |ch| ch.target_strategy.label != "Retargeting" }.take(5)
      end

      strategies[0], strategies[1] = strategies[1], strategies[0] if strategies.first.target_strategy.label == "Retargeting"
      strategies.compact!

      return [] if strategies[0].target_strategy.label == "Retargeting"

      strategies.map do |st|
        # @see: MediaOutputTargetStrategy model associations
        {
          ad_format_id: st.ad_format.id,
          ad_format: {id: st.ad_format.id, label: st.ad_format.label},
          target_strategy_id: st.target_strategy.id,
          target_strategy: {id: st.target_strategy.id, label: st.target_strategy.label},
          master_relationship_id: st.id,
          target_id: st.target.id,
          target: {id: st.target.id, label: st.target.label},
          media_platform_id: st.media_platform.id,
          media_platform: {id: st.media_platform.id, label: st.media_platform.label}
        }
      end
    end

    def campaign_channel_ids
      @campaign_channel_ids ||= CampaignChannel.where.not(value: excluded_channels).pluck(:id)
    end

    def excluded_channels
      media_brief.campaign_channels.select { |k, v| v }.keys - creative_assets
    end

    def creative_assets
      media_brief.creative_assets.select { |k, v| v }.keys
    end

    # @return [Array<[CampaignChannel, Array<MasterRelationship>]>] master relationships grouped by campaign channel
    def channels
      @channels ||= MasterRelationship.joins(:campaign_channel, :target_strategy).includes(:campaign_channel, :target_strategy).where(
        campaign_objective: media_brief.campaign_objective,
        campaign_initiative: media_brief.campaign_initiative,
        campaign_channel: campaign_channel_ids
      ).where.not(priority: nil).order(:priority).group_by { |mr| mr.campaign_channel }.to_a
    end
  end
end
