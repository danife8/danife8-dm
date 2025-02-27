# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide3
      class Slide3 < Base
        CM = 360000
        PPT_WIDTH = 33.8

        def call
          icons.uniq! { |icon| icon[:id] }

          center = PPT_WIDTH / 2
          width = 6.86868056
          offset = (center - width * icons.size / 2 - width) * CM

          icons.map! do |icon|
            offset += width * CM

            {
              id: icon[:id],
              off_x: offset.to_i,
              label: icon[:label]
            }
          end

          {
            icons:
          }
        end

        def icons
          @icons ||= resource.media_plan_output.media_plan_output_rows.map do |row|
            {id: row.campaign_channel.value, label: row.campaign_channel.label}
          end
        end
      end
    end
  end
end
