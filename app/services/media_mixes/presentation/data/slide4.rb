# frozen_string_literal: true

module MediaMixes
  module Presentation
    module Data
      # MediaMixes::Presentation::Data::Slide4
      class Slide4 < MediaPlans::Presentation::Data::Slide4
        def media_mix
          @media_mix ||= resource
        end
      end
    end
  end
end
