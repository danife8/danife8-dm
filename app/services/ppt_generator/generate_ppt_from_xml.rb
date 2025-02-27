# frozen_string_literal: true

module PptGenerator
  # PptGenerator::GeneratePptFromXml
  class GeneratePptFromXml
    def initialize(tmpdir, destination_file)
      @tmpdir = tmpdir
      @destination_file = destination_file
    end

    attr_accessor :tmpdir, :destination_file

    def call
      output_file_path = Rails.root.join("tmp", destination_file)
      File.delete(output_file_path) if File.exist?(output_file_path)

      zf = GenerateZipFile.new(tmpdir, output_file_path)
      zf.write

      output_file_path
    end
  end
end
