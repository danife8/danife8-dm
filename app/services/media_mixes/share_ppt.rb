# frozen_string_literal: true

module MediaMixes
  require "pptx"

  class SharePpt
    include ActionView::Helpers::NumberHelper
    include MediaMixHelper

    def initialize(media_mix)
      @media_mix = media_mix
      @media_output = media_mix.media_output
      @final_output = @media_output.present? ? @media_output.channel_strategies.last : nil
      @p = PPTX::OPC::Package.new
    end

    def call
      build_ppt_file
      p.to_zip
    end

    private

    attr_accessor :media_mix, :media_output, :final_output, :p

    def build_ppt_file
      add_slide("Media Mix Data", media_mix_slide, 6)

      final_output_slides.each do |final_output_slide|
        add_slide("Final Output Data", final_output_slide, 5)
      end
    end

    def add_slide(title, slides, column_width)
      slide = PPTX::Slide.new(p)
      slide.add_textbox(PPTX.cm(1, 1, 22, 2), title, sz: 24 * PPTX::POINT)

      slides.each_with_index do |row, row_index|
        y_position = 3 + row_index * 2

        row.each_with_index do |cell, cell_index|
          x_position = 1 + (cell_index * column_width)
          slide.add_textbox(PPTX.cm(x_position, y_position, column_width, 2), cell.to_s, sz: (row_index.zero? ? 20 : 16) * PPTX::POINT)
        end
      end

      p.presentation.add_slide(slide)
    end

    def media_mix_slide
      [
        ["Title", "Client", "Media Brief", "Status"],
        [media_mix.title, media_mix.client.name, media_mix.media_brief.title, media_mix_status(media_mix.aasm_state)]
      ]
    end

    def final_output_slides
      return [[["No data."]]] unless final_output.present?

      slides = [[["Channel", "Campaign Objective", "Ad Platform", "Target Strategy", "Budget"]]]

      final_output.primary_channels.each do |channel|
        channel.target_strategies.each do |strategy|
          slides.last << build_strategy_row(channel, strategy)
        end
      end

      if final_output.secondary_channels.present?
        slides.last << ["", "", "", "", ""]
        final_output.secondary_channels.each do |channel|
          channel.target_strategies.each do |strategy|
            slides.last << build_strategy_row(channel, strategy)
          end
        end
      end

      slides.last << ["Total", "", "", "", sum_amts(final_output)]

      # Split into multiple slides if rows exceed 8
      split_into_slides(slides)
    end

    def build_strategy_row(channel, strategy)
      [
        channel.campaign_channel.label,
        media_output.campaign_objective.label,
        strategy.ad_format.label,
        strategy.target_strategy.label,
        currency(strategy.amt)
      ]
    end

    def split_into_slides(slides, max_rows_per_slide: 8)
      split_slides = []
      current_slide = []

      slides.first.each_with_index do |row, index|
        if index % max_rows_per_slide == 0 && index > 0
          split_slides << current_slide
          # Add header row to new slide
          current_slide = [slides.first.first]
        end
        current_slide << row
      end

      split_slides << current_slide unless current_slide.empty?

      split_slides
    end
  end
end
