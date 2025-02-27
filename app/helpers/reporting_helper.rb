module ReportingHelper
  def active_class(reporting_dashboard)
    return "btn-primary" if reporting_dashboard.id == params[:id].to_i || (params[:id].blank? && collection.first.try(:[], :id) == reporting_dashboard.id)

    "btn-link"
  end
end
