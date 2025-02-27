# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Base
      class Base
        def initialize(resource)
          @resource = resource
        end

        protected

        attr_accessor :resource
      end
    end
  end
end
