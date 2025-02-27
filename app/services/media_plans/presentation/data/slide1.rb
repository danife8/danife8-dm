# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide1
      class Slide1 < Base
        def call
          {
            title: "Digital Media Recommendation",
            subtitle: resource.created_at.strftime("%B %Y")
          }
        end
      end
    end
  end
end
