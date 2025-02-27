module MediaBriefGeographicTargeting
  extend ActiveSupport::Concern

  included do
    attr_accessor :geographic_target, :multi_local_option

    after_find :determine_geographic_target, :determine_multi_local_option
    after_initialize :initialize_geographic_targeting, if: :new_record?

    before_validation :set_geographic_targets
  end

  private

  def initialize_geographic_targeting
    determine_geographic_target
    determine_multi_local_option
  end

  def set_geographic_targets
    targets = GeographicTarget.value_hash

    if geographic_target == "multi_local"
      update_targets_for_multi_local(targets)
    end

    targets[geographic_target] = true if targets.key?(geographic_target)
    self.geographic_targets = targets
  end

  def update_targets_for_multi_local(targets)
    case multi_local_option
    when "city_state"
      targets["city_state"] = true
    when "zip"
      targets["zip"] = true
    when "city_state_zip"
      targets["city_state"] = true
      targets["zip"] = true
    end
  end

  def determine_geographic_target
    self.geographic_target = geographic_targets.find { |_key, value| value }&.first
  end

  def determine_multi_local_option
    return unless geographic_targets["multi_local"]

    is_zip = geographic_targets["zip"]
    is_city_state = geographic_targets["city_state"]

    self.multi_local_option = if is_zip && is_city_state
      "city_state_zip"
    elsif is_zip
      "zip"
    elsif is_city_state
      "city_state"
    end
  end
end
