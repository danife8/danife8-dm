# frozen_string_literal: true

module PptGenerator
  # PptGenerator::ExtractXml
  class ExtractXml
    def initialize(tmpdir, template_path)
      @tmpdir = tmpdir
      @template_path = template_path
    end

    attr_accessor :tmpdir, :template_path

    def call
      Zip::File.open(template_path) do |zip_file|
        zip_file.each do |file|
          file_path = File.join(tmpdir, file.name)
          FileUtils.mkdir_p(File.dirname(file_path))
          zip_file.extract(file, file_path)
        end
      end
    end
  end
end
