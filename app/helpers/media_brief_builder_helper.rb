# frozen_string_literal: true

module MediaBriefBuilderHelper
  def campaign_select_class(campaign, type)
    campaign = "blank" unless campaign.present?

    "d-none" if campaign != type
  end

  def campaign_disabled?(campaign, type)
    campaign = "blank" unless campaign.present?

    campaign != type
  end

  def other_tracking_capability_disabled?(media_brief_builder)
    media_brief_builder.tracking_capability == "other"
  end

  def boolean_with_idnk_select_options(enum_model)
    enum_model.all
  end

  def boolean_select_options
    [["Yes", true], ["No", false]]
  end

  def creative_asset_options
    CampaignChannel.all.sort_by(&:position)
  end

  def campaign_channel_options
    CampaignChannel.all.sort_by(&:position)
  end

  def social_platform_options
    SocialPlatform.all.sort_by(&:position)
  end

  def enum_model_options(enum_model)
    enum_model.all.sort_by(&:position)
  end

  def enum_model_select_options(enum_model)
    enum_model.all.sort_by(&:position).map do |instance|
      [instance.label, instance.value]
    end
  end

  def step_title(resource)
    step = current_media_brief_wizard_step(resource)

    [
      "Campaign Definitions",
      "Campaign Definitions",
      "Industry Targeting",
      "Demographic Targeting",
      "Geographic Targeting",
      "Reporting & Tracking",
      "Creative Details"
    ][step - 1]
  end

  def next_media_brief_wizard_step(resource)
    current_media_brief_wizard_step(resource) + 1
  end

  def current_media_brief_wizard_step(resource)
    return resource.current_step_was unless params[:step].present?
    return resource.current_step_was if params[:step].to_i > resource.current_step_was

    params[:step].to_i
  end

  def edit_media_brief_step(step, back_to_step = 8)
    edit_media_brief_builder_path(resource, step:, back_to_step:)
  end

  def gender_icon(gender)
    {
      unknown: "bi-gender-ambiguous",
      female: "bi-gender-female",
      male: "bi-gender-male",
      all: "bi-gender-trans"
    }[gender.to_sym]
  end

  def enum_truly(data)
    data.select { |_k, v| v }
  end

  def geographic_by_type(resource, type)
    fields = {
      multi_state: :state,
      city_state: :city_state,
      zip: :zipcode,
      local: [:local_city_state, :radius],
      georadius: [:address, :radius]
    }
    sym_type = type.to_sym

    keys = fields[sym_type]
    return [] unless keys

    Array(keys).map do |key|
      if key === :radius
        "Radius: " + resource.send(key)&.to_s
      else
        resource.send(key)&.to_s&.split("\n")
      end
    end.flatten
  end

  def boolean_to_text(boolvalue)
    boolvalue ? "YES" : "NO"
  end

  def demographic_details_prefix_options
    DemographicDetailsPrefix.all.sort_by(&:position).map { |p| [p.label, p.key] }
  end
end
