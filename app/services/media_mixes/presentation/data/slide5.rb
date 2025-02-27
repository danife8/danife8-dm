# frozen_string_literal: true

module MediaMixes
  module Presentation
    module Data
      # MediaMixes::Presentation::Data::Slide5
      class Slide5 < MediaPlans::Presentation::Data::Slide5
        def channels
          return @channels if @channels

          final = resource.media_output.channel_strategies.last

          channels = []

          channels += final.primary_channels.map do |channel|
            channel.campaign_channel.value
          end

          channels += final.secondary_channels.map do |channel|
            channel.campaign_channel.value
          end

          @channels = channels.uniq
        end
      end
    end
  end
end
