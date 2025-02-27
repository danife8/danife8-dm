# Common media brief data validators for custom data types.
module MediaBriefValidationHelpers
  extend ActiveSupport::Concern

  private

  # Verify that the campaign channel hash is valid.
  # @see CampaignChannel
  def campaign_channels_hash
    return unless campaign_channels.present?

    if campaign_channels.keys.sort != CampaignChannel.valid_keys
      errors.add(:campaign_channels, "must contain valid campaign channel keys")
    end

    if campaign_channels.values.detect { |v| ![true, false].include?(v) }
      errors.add(:campaign_channels, "must contain boolean values")
    end
  end

  # Verify that the campaign initiative scopes to the objective.
  # @see CampaignInitiative
  def campaign_initiative_scoped_to_objective
    unless campaign_initiative&.campaign_objective == campaign_objective
      errors.add(:campaign_initiative, "must belong to campaign objective")
    end
  end

  # Verify that the creative assets hash is valid.
  # @see CampaignChannel
  def creative_assets_hash
    return unless creative_assets.present?

    if creative_assets.keys.sort != CampaignChannel.valid_keys
      errors.add(:creative_assets, "must contain valid creative asset keys")
    end

    if creative_assets.values.detect { |v| ![true, false].include?(v) }
      errors.add(:creative_assets, "must contain boolean values")
    end
  end

  # Verify that the demographic age hash is valid.
  # @see DemographicAge
  def demographic_ages_hash
    return unless demographic_ages.present?

    if demographic_ages.keys.sort != DemographicAge.valid_keys
      errors.add(:demographic_ages, "must contain valid demographic age keys")
    end

    if demographic_ages.values.detect { |v| ![true, false].include?(v) }
      errors.add(:demographic_ages, "must contain boolean values")
    end
  end

  # Verify that the demographic gender hash is valid.
  # @see DemographicGender
  def demographic_genders_hash
    return unless demographic_genders.present?

    if demographic_genders.keys.sort != DemographicGender.valid_keys
      errors.add(:demographic_genders, "must contain valid demographic gender keys")
    end

    if demographic_genders.values.detect { |v| ![true, false].include?(v) }
      errors.add(:demographic_genders, "must contain boolean values")
    end
  end

  # Verify that the geographic target hash is valid.
  # @see GeographicTarget
  def geographic_targets_hash
    return unless geographic_targets.present?

    if geographic_targets.keys.sort != GeographicTarget.valid_keys
      errors.add(:geographic_targets, "must contain valid geographic target keys")
    end

    if geographic_targets.values.detect { |v| ![true, false].include?(v) }
      errors.add(:geographic_targets, "must contain boolean values")
    end
  end

  # Verify that the social advertising access hash is valid.
  # @see SocialPlatform
  def social_advertising_access_hash
    return unless social_advertising_access.present?

    if social_advertising_access.keys.sort != SocialPlatform.valid_keys
      errors.add(:social_advertising_access, "must contain valid social platform keys")
    end

    if social_advertising_access.values.detect { |v| ![true, false].include?(v) }
      errors.add(:social_advertising_access, "must contain boolean values")
    end
  end

  # Verify that the social platform hash is valid.
  # @see SocialPlatform
  def social_platforms_hash
    return unless social_platforms.present?

    if social_platforms.keys.sort != SocialPlatform.valid_keys
      errors.add(:social_platforms, "must contain valid social platform keys")
    end

    if social_platforms.values.detect { |v| ![true, false].include?(v) }
      errors.add(:social_platforms, "must contain boolean values")
    end
  end

  # Validate that all associated geographic filters are present according to selected
  # geographic targets.
  # @see GeographicTarget
  # @see GeographicFilter
  def geographic_filters_details
    return unless geographic_targets

    if geographic_targets["multi_state"] && geographic_filters_by_type("StateFilter").empty?
      errors.add(:geographic_filters, "should include states information.")
    end
    if geographic_targets["multi_local"] && multi_local_option.blank?
      errors.add(:multi_local_option, "should include information.")
    end
    if geographic_targets["city_state"] && geographic_filters_by_type("CityStateFilter").empty?
      errors.add(:geographic_filters, "should include city/states information.")
    end
    if geographic_targets["zip"] && geographic_filters_by_type("ZipcodeFilter").empty?
      errors.add(:geographic_filters, "should include zipcodes information.")
    end
    if geographic_targets["local"] && radius.blank?
      errors.add(:radius, "should include information.")
    end
    if geographic_targets["local"] && geographic_filters_by_type("CityStateFilter").empty?
      errors.add(:geographic_filters, "should include city/state information.")
    end
    if geographic_targets["georadius"] && geographic_filters_by_type("AddressFilter").empty?
      errors.add(:geographic_filters, "should include addresses information.")
    end
    if geographic_targets["georadius"] && radius.blank?
      errors.add(:radius, "should include information.")
    end
  end
end
