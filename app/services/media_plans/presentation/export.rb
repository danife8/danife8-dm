# frozen_string_literal: true

module MediaPlans
  module Presentation
    # PptGenerator::Export
    class Export
      TEMPLATE_PATH = Rails.root.join("app", "assets", "templates", "media_plan.pptx")

      def initialize(resource)
        @resource = resource
        @destination_file = "media-plan-#{resource.title.parameterize}-#{resource.id}.pptx"
      end

      def call
        PptGenerator::Export.new(self.class::TEMPLATE_PATH, destination_file, variables).call do |tmpdir|
          copy_files(tmpdir)
        end
      end

      protected

      attr_accessor :resource, :tmpdir, :destination_file

      def copy_files(tmpdir)
        ref = File.join(tmpdir, "ppt", "slides", "_rels", "slide3.xml.rels")
        doc = Nokogiri::XML(File.open(ref))

        Dir.glob(File.join(Rails.root, "app/assets/images/ppt_icons", "*.png")).each do |image|
          img = image.split("/").last
          img_name = img.split(".").first
          new_relationship = Nokogiri::XML::Node.new("Relationship", doc)
          new_relationship["Id"] = img_name
          new_relationship["Type"] = "http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
          new_relationship["Target"] = "../media/#{img}"
          doc.at("Relationships").add_child(new_relationship)
        end

        File.write(ref, doc.to_xml)

        # Copy files
        FileUtils.cp_r(Rails.root.join("app/assets/images/ppt_icons/."), "#{tmpdir}/ppt/media/")
      end

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
            media_plan_table: method(:media_plan_table)
          }
        }
      end

      def media_plan_table
        @media_plan_table ||= Data::Slide16.new(resource).table
      end
    end
  end
end
