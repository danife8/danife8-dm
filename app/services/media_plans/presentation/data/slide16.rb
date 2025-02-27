# frozen_string_literal: true

module MediaPlans
  module Presentation
    module Data
      # MediaPlans::Presentation::Data::Slide16
      class Slide16 < Base
        VIEW = "slide16"

        def table
          controller = ActionController::Base.new
          controller.class.helper MediaPlanHelper
          controller.class.helper MediaMixHelper
          controller.class.helper MasterRelationshipHelper
          controller.prepend_view_path Rails.root.join("app/services/media_plans/presentation/views/")

          controller.render_to_string(
            template: VIEW,
            layout: false,
            locals: {resource: resource, rows:, media_output: resource.media_mix.media_output}
          )
        end

        def rows
          resource
            .media_plan_output
            .media_plan_output_rows
            .except(:order)
            .includes(:campaign_channel)
            .joins(:campaign_channel)
            .order("campaign_channels.position ASC")
        end
      end
    end
  end
end
