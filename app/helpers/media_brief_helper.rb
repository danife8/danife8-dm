module MediaBriefHelper
  def media_brief_status(status)
    {active: "Active", modified: "Modified", approved: "Approved"}[status.to_sym] || ""
  end

  def filter_by(filter)
    return params.to_unsafe_h.except(:sort) if params[:sort] == filter

    params.to_unsafe_h.merge(sort: filter)
  end

  def filter_class(filter)
    return "btn-primary" if params[:sort] == filter || (params[:sort].blank? && filter == "created_at.desc")

    "btn-link"
  end

  def title_secuence(client = nil)
    return "" if current_user.super_admin? && !client

    agency = client ? client.agency : current_user.agency
    secuence = agency.media_brief_builders.where(created_at: Date.today.beginning_of_day..Date.today.end_of_day).count + 1
    date = Time.zone.now.strftime("%m.%d.%Y")
    "MB-#{secuence.to_s.rjust(2, "0")}-#{date}"
  end

  def previous_data_value_to_label(value)
    data = MediaBriefPreviousData::OPTIONS.detect do |option|
      option[:value] == value
    end
    data ? data[:label] : "N/A"
  end

  def media_plans_present?(media_brief)
    !!media_brief.newest_media_mix&.media_plans&.any?
  end

  def editing?(step)
    step.present? && step.to_i != 8
  end
end
