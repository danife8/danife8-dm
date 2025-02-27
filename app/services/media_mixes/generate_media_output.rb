# frozen_string_literal: true

module MediaMixes
  class GenerateMediaOutput
    TRANSFORM_KEYS = %i[
      channel_strategies
      primary_channels
      secondary_channels
      target_strategies
      channel
      target_strategy
      campaign_channel
      campaign_objective
      campaign_initiative
      ad_format
      target
      media_platform
    ]

    def initialize(media_mix)
      @media_mix = media_mix
      @collection = Collection.new(media_mix.media_brief).call if media_mix.media_brief.present?
    end

    def call
      unless media_mix.media_brief.present?
        Rails.logger.info("Media Output for Media Mix ##{media_mix.id} could not be generated because it has no Media Brief")
        return {error: true, errors: ["The Media Mix has no Media Brief."]}
      end

      rename_keys!(collection)

      version = MediaOutput.where(media_mix:).count + 1

      media_mix.update(media_output_version: version)
      media_mix.create_media_output(collection.merge(version:))

      return {error: true, errors: media_mix.media_output.errors.full_messages} unless media_mix.media_output.persisted?

      {error: false, errors: []}
    end

    protected

    attr_accessor :collection, :media_mix

    def rename_keys!(hash)
      hash.transform_keys! do |key|
        if key.to_s.end_with?("_attributes") || !TRANSFORM_KEYS.include?(key)
          key
        else
          :"#{key}_attributes"
        end
      end

      hash.each do |key, value|
        if value.is_a?(Array)
          value.each { |item| rename_keys!(item) if item.is_a?(Hash) }
        elsif value.is_a?(Hash)
          rename_keys!(value)
        end
      end

      hash
    end
  end
end
