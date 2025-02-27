# app/services/media_briefs/share_ppt.rb
module MediaBriefs
  require "pptx"
  class SharePpt
    include MediaBriefBuilderHelper

    def initialize(media_brief)
      @media_brief = media_brief
      @p = PPTX::OPC::Package.new
    end

    def call
      build_ppt_file
      p.to_zip
    end

    private

    attr_accessor :media_brief, :p

    def build_ppt_file
      add_step_to_ppt("Step 1", build_step_1)
      add_step_to_ppt("Step 2", build_step_2)
      add_step_to_ppt("Step 3", build_step_3)
      add_step_to_ppt("Step 4", build_step_4)
      add_step_to_ppt("Step 5", build_step_5)
      add_step_to_ppt("Step 6", build_step_6)
      add_step_to_ppt("Step 7", build_step_7)
    end

    def add_step_to_ppt(step_name, content)
      slide = PPTX::Slide.new(p)
      slide.add_textbox(PPTX.cm(2, 1, 22, 1), step_name, sz: 20 * PPTX::POINT)

      content.each_with_index do |row, index|
        y_position = 4 + index * 2
        slide.add_textbox(PPTX.cm(2, y_position, 22, 2), row.join("\n"))
      end

      p.presentation.add_slide(slide)
    end

    def build_step_1
      [
        ["Media brief title", media_brief.title],
        ["Client", media_brief.client.name],
        ["Campaign Objective", media_brief.campaign_objective.label],
        ["Campaign Initiative", media_brief.campaign_initiative.label]
      ]
    end

    def build_step_2
      [
        ["Campaign Duration", "#{media_brief.campaign_starts_on.strftime("%m/%d/%Y")} - #{media_brief.campaign_ends_on.strftime("%m/%d/%Y")}"],
        ["Budget", media_brief.campaign_budget],
        ["Destination URL", media_brief.destination_url],
        ["Official Social Platforms", media_brief.social_platforms_list.map(&:label)],
        ["Advertising Enabled", media_brief.social_advertising_access_list.map { |sa| "#{sa.label} - #{sa.value}" }]
      ]
    end

    def build_step_3
      [
        ["Industry Target", IndustryTarget.find(media_brief.industry_target).label],
        ["Industry Category Descriptions", media_brief.industry_description1, media_brief.industry_description2, media_brief.industry_description3, media_brief.industry_description4, media_brief.industry_description5]
      ]
    end

    def build_step_4
      [
        ["All ages and genders", media_brief.all_demographics],
        ["Targeted Gender(s)", media_brief.all_demographics ? "ALL" : media_brief.demographic_genders_list.map(&:label)],
        ["Age(s)", media_brief.all_demographics ? "ALL" : media_brief.demographic_ages_list],
        ["Additional Demographic Details"] + additional_demographic_details
      ]
    end

    def build_step_5
      geographic_data = []

      media_brief.geographic_targets.each do |key, value|
        geographic_data << [GeographicTarget.find(key).label]
        media_brief.geographic_filters.select { |geographic_filter| geographic_filter.type == key }.map do |text|
          (key == "local") ? "Radius: #{text}" : text
        end
      end

      [["How do you want the media delivered, geographically?"]] + geographic_data
    end

    def build_step_6
      [
        ["Do you have any current/previous digital campaign results to share?", MediaBriefPreviousData.find(media_brief.previous_campaign_data).label],
        ["Is there any current/previous customer data (CRM) available to use?", MediaBriefPreviousData.find(media_brief.previous_customer_data).label],
        ["Is there access to place tracking & reporting pixels?", media_brief.tracking_pixel_access]
      ]
    end

    def build_step_7
      available_creative_assets = media_brief.creative_assets.map do |key, value|
        key if value == true
      end.compact
      [
        ["Available Creative Assets", available_creative_assets],
        ["Excluded Channels", media_brief.campaign_channels.map { |key, value| CampaignChannel.find_by(value: key).label }]
      ]
    end

    def additional_demographic_details
      (1..5).map do |i|
        prefix = media_brief.send(:"demographic_details#{i}_prefix")
        detail = media_brief.send(:"demographic_details#{i}")
        prefix_label = DemographicDetailsPrefix.find(prefix).try(:label)

        "#{prefix_label.present? ? "#{prefix_label}: " : ""}#{detail}"
      end
    end
  end
end
