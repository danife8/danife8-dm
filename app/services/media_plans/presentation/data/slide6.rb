# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide6
      class Slide6 < Base
        include MediaBriefBuilderHelper

        def call
          geographics = enum_truly(media_brief.geographic_targets).map do |key, _v|
            items = []

            if geographic_by_type(media_brief, key).present?
              geographic_by_type(media_brief, key).each do |text|
                items << text
              end
            end

            {
              label: GeographicTarget.find(key).label,
              items:
            }
          end

          {
            geographics:
          }
        end

        def media_brief
          @media_brief ||= resource.media_brief
        end
      end
    end
  end
end
