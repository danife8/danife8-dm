# frozen_string_literal: true

module MediaMixes
  module Presentation
    # MediaMixes::Presentation::Export
    class Export < MediaPlans::Presentation::Export
      TEMPLATE_PATH = Rails.root.join("app", "assets", "templates", "media_mix.pptx")

      def initialize(resource)
        @resource = resource
        @destination_file = "media-mix-#{resource.title.parameterize}-#{resource.id}.pptx"
      end

      protected

      def variables
        return @variables if @variables.present?

        slide_1 = Data::Slide1.new(resource).call
        slide_2 = Data::Slide2.new(resource).call
        slide_3 = Data::Slide3.new(resource).call
        slide_4 = Data::Slide4.new(resource).call
        slide_5 = Data::Slide5.new(resource).call
        slide_6 = Data::Slide6.new(resource).call
        overlays = slide_5[:channels].include?("display") ? MediaPlans::AudienceOverlay.new(resource).call : []
        keywords = slide_5[:channels].include?("search") ? MediaPlans::KeywordGenerator.new(resource).call : []

        keywords_col1, keywords_col2 = keywords.each_slice(10).to_a

        @variables = {
          slide_1:,
          slide_2:,
          slide_3:,
          slide_4:,
          slide_5:,
          slide_6:,
          overlays:,
          keywords:,
          keywords_col1: keywords_col1 || [],
          keywords_col2: keywords_col2 || [],
          optimized: {
            media_mix_table: method(:media_mix_table)
          }
        }
      end

      def media_mix_table
        @media_mix_table ||= Data::Slide16.new(resource).table
      end
    end
  end
end
