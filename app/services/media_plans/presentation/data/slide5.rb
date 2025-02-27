# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide5
      class Slide5 < Base
        def call
          benefits1, benefits2 = channels.each_slice(4).to_a

          {
            channels:,
            benefits1: benefits1 || [],
            benefits2: benefits2 || []
          }
        end

        def channels
          @channels ||= resource.media_plan_output.media_plan_output_rows.map do |row|
            row.campaign_channel.value
          end.uniq
        end
      end
    end
  end
end
