# frozen_string_literal: true

module PptGenerator
  # PptGenerator::Export.new(template_path, destination_file, variables).call
  class Export
    CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    DISPOSITION = "attachment"

    def initialize(template_path, destination_file, variables, tmpdir = Dir.mktmpdir)
      @template_path = template_path
      @destination_file = destination_file
      @variables = variables
      @tmpdir = tmpdir
    end

    def call
      ExtractXml.new(tmpdir, template_path).call
      yield(tmpdir)
      ReplaceVariables.new(tmpdir, variables).call
      GeneratePptFromXml.new(tmpdir, destination_file).call
    end

    protected

    attr_accessor :template_path, :destination_file, :variables, :tmpdir
  end
end
