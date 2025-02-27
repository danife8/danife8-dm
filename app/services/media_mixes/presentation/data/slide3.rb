# frozen_string_literal: true

module MediaMixes
  module Presentation
    module Data
      # MediaMixes::Presentation::Data::Slide3
      class Slide3 < MediaPlans::Presentation::Data::Slide3
        def icons
          return @icons if @icons

          final = resource.media_output.channel_strategies.last

          @icons = []

          @icons += final.primary_channels.map do |channel|
            {id: channel.campaign_channel.value, label: channel.campaign_channel.label}
          end

          @icons += final.secondary_channels.map do |channel|
            {id: channel.campaign_channel.value, label: channel.campaign_channel.label}
          end

          @icons
        end
      end
    end
  end
end
