# frozen_string_literal: true

module PptGenerator
  # PptGenerator::ReplaceVariables
  class ReplaceVariables
    def initialize(tmpdir, variables)
      @tmpdir = tmpdir
      @variables = variables
    end

    attr_accessor :tmpdir, :variables

    def call
      files = File.join(tmpdir, "**", "slides", "*.xml")

      Dir.glob(files).each_with_index do |file, index|
        process_file(file, index)
      end
    end

    def process_file(file, index)
      txt = File.read(file)
      return unless txt.match?("{{")
      missing_partials = []

      txt = partial_formatter(txt)
      puts "template start #{file}"
      hbs = Handlebars::Engine.new
      hbs.register_partial("image", File.read(Rails.root.join("app/services/ppt_generator/views/image.hbs")))
      hbs.register_helper("include") do |context, value, array|
        array.include?(value)
      end

      hbs.register_partial_missing do |name|
        missing_partials << name

        "{#{name}}"
      end

      render = hbs.compile(txt).call(variables)

      # Replace large views
      missing_partials.each do |partial|
        render.gsub!("{#{partial}}", variables[:optimized][partial.to_sym].call) if render.match?(partial)
      end

      return remove_slide(file, render) if render.match?("REMOVE THIS SLIDE")

      File.write(file, render)
    end

    def remove_slide(file, render)
      file_name = file.split("/").last

      doc = Nokogiri::XML(File.read("#{tmpdir}/[Content_Types].xml"))
      rels_doc = Nokogiri::XML(File.read("#{tmpdir}/ppt/_rels/presentation.xml.rels"))
      presentation_doc = Nokogiri::XML(File.read("#{tmpdir}/ppt/presentation.xml"))
      node = doc.at_xpath("//xmlns:Override[contains(@PartName, '/ppt/slides/#{file_name}')]")
      node&.remove

      node = rels_doc.at_xpath("//xmlns:Relationship[contains(@Target, 'slides/#{file_name}')]")

      pre_node = presentation_doc.at_xpath("//p:sldId[contains(@r:id, '#{node["Id"]}')]")
      pre_node&.remove

      File.write("#{tmpdir}/[Content_Types].xml", doc.to_xml)
      File.write("#{tmpdir}/ppt/presentation.xml", presentation_doc.to_xml)
      File.delete(file)
    end

    def partial_formatter(txt)
      convert_special_chars(txt)

      doc = Nokogiri::XML(txt)

      each_pattern = /{{#each[^{]*?}}(.*?)({{\/each}})/m
      partial_pattern = /{{\s*>\s*[a-zA-Z0-9_ ]+(?:\s+[a-zA-Z0-9_='\(\)\-\@\.\#]+)*\s*}}/

      doc.xpath("//p:sp").each do |content_node|
        next unless content_node.content.match?(partial_pattern)
        pattern = content_node.content.match?(each_pattern) ? each_pattern : partial_pattern

        if content_node.content.match?(pattern)
          new_content = content_node.content.gsub(pattern) do |match|
            match
          end

          content_node.before(new_content)
          content_node.remove
        end
      end

      txt = doc.to_xml
      convert_special_chars(txt)

      txt
    end

    def convert_special_chars(txt)
      txt.gsub!("{{&gt;", "{{>")
      txt.gsub!(/’|‘/, "'")
    end
  end
end
