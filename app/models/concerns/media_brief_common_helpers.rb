# Common media brief data validators for custom data types.
module MediaBriefCommonHelpers
  extend ActiveSupport::Concern

  def state
    geographic_filter_by_lines(:state, "StateFilter")
  end

  def city_state
    geographic_filter_by_lines(:city, "CityStateFilter")
  end

  def address
    geographic_filter_by_lines(:address, "AddressFilter")
  end

  def zipcode
    geographic_filter_by_lines(:zipcode, "ZipcodeFilter")
  end

  def local_city_state
    geographic_filter_by_lines(:local_city_state, "CityStateFilter")
  end

  def social_platforms_list
    social_platforms.select { |k, v| v }.map do |key, value|
      SocialPlatform.find(key)
    end
  end

  def demographic_genders_list
    demographic_genders.select { |k, v| v }.map do |key, value|
      OpenStruct.new(key:, label: DemographicGender[key])
    end
  end

  def demographic_ages_list
    demographic_ages.select { |k, v| v }.map do |key, value|
      DemographicAge[key]
    end
  end

  def social_advertising_access_list
    social_advertising_access.map do |key, value|
      OpenStruct.new(label: SocialPlatform.find(key).label, value:)
    end
  end

  def geographic_filters_by_type(type)
    geographic_filters.select { |geographic_filter| geographic_filter.type == type }
  end

  protected

  def geographic_filter_by_lines(field_name, type)
    self[field_name] || geographic_filters_by_type(type).select { |geographic_filter| valid? || !geographic_filter.persisted? }.map(&:line).join("\n")
  end
end
