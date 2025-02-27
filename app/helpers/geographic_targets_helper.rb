module GeographicTargetsHelper
  def hidden_class(should_hide)
    should_hide ? "d-none" : ""
  end

  def should_disable?(should_disable)
    should_disable
  end

  def dependent_fields_map
    {
      main: {
        "national" => [],
        "multi_state" => ["textbox-multi_state"],
        "multi_local" => ["dropdown-multi_local"],
        "local" => ["textbox-local_city_state", "textbox-radius"],
        "georadius" => ["textbox-address", "textbox-radius"]
      },
      sub: {
        "city_state" => ["textbox-city_state"],
        "zip" => ["textbox-zip"],
        "city_state_zip" => ["textbox-city_state", "textbox-zip"]
      }
    }
  end

  def multi_local_options
    options = GeographicTarget.not_main.map { |gt| [gt.label, gt.key] }
    options << ["Cities and ZIP codes", "city_state_zip"]
    options
  end
end
