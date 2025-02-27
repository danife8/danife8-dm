# frozen_string_literal: true

module MediaMixes
  module Presentation
    module Data
      # MediaMixes::Presentation::Data::Base
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
