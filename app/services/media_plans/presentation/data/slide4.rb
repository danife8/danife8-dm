# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide4
      class Slide4 < Base
        def call
          channels = []

          final = media_mix.media_output.channel_strategies.last

          channels += format_channel(final.primary_channels)
          channels += format_channel(final.secondary_channels)

          {
            channels:
          }
        end

        protected

        def format_channel(channels)
          data = []

          channels.each do |channel|
            strategies = channel.target_strategies.map do |strategy|
              strategy.target_strategy.label
            end

            data << {
              label: channel.campaign_channel.label,
              strategies:
            }
          end

          data
        end

        def media_mix
          @media_mix ||= resource.media_mix
        end
      end
    end
  end
end
