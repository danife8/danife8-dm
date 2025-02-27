# frozen_string_literal: true

module MediaMixes
  module Presentation
    module Data
      # MediaMixes::Presentation::Data::Slide16
      class Slide16 < Base
        VIEW = "slide16"

        def table
          controller = ActionController::Base.new
          controller.class.helper MediaPlanHelper
          controller.class.helper MediaMixHelper
          controller.class.helper MasterRelationshipHelper
          controller.prepend_view_path Rails.root.join("app/services/media_mixes/presentation/views/")

          controller.render_to_string(
            template: VIEW,
            layout: false,
            locals: {engine: resource.media_output.channel_strategies.last, media_output: resource.media_output}
          )
        end
      end
    end
  end
end
