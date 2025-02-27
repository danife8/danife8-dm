module MediaPlanHelper
  def sum_imprs(media_plan)
    total = media_plan.media_plan_output.media_plan_output_rows.sum { |row| row.impressions }
    format_decimal_number(total)
  end

  def sum_media_plan_amts(media_plan)
    total = media_plan.media_plan_output.media_plan_output_rows.sum { |row| row.amt }
    currency(total)
  end

  def format_cpm(cpm, target_strategy)
    return "Included above" if is_retargeting(target_strategy)

    cpm_to_currency(cpm)
  end

  def format_impr(impressions, target_strategy)
    return "Included above" if is_retargeting(target_strategy)

    format_decimal_number(impressions)
  end

  def format_decimal_number(number)
    number_with_precision(number, precision: 2, delimiter: ",")
  end

  def media_plan_status(status, deleted = false)
    return "Archived" if deleted

    {
      created: "Created",
      in_review: "In Review",
      assigned_to_reviewer: "Assigned to Review Expert",
      approved: "Approved",
      rejected: "Rejected"
    }[status.to_sym] || ""
  end

  def media_plan_creator_status(status, deleted = false)
    return "Archived" if deleted

    {
      user_created: "Created",
      user_waiting_for_reviewer: "Waiting for Reviewer",
      user_in_review: "In Review",
      user_approved: "Approved",
      user_rejected: "Rejected"
    }[status.to_sym] || ""
  end

  def media_plan_modified_status(media_plan)
    return "Modified; " if (media_plan.in_review? || media_plan.approved?) && media_plan.media_plan_output&.modified_by_user_at
    return "Modified; " if (media_plan.approved? || media_plan.rejected?) && media_plan.media_plan_output&.modified_by_reviewer_at

    ""
  end

  def reviewer_options
    [["Assign to me", current_user.id]] + reviewers.where.not(id: current_user.id).map { |u| [u.full_name, u.id] }
  end

  def media_plan_history_changed_by(media_plan_history)
    policy_scope(User).find_by_id(media_plan_history.whodunnit)&.full_name
  end

  def media_plan_history_comment(media_plan_history)
    return media_plan_history.reject_comment if media_plan_history.aasm_state == "rejected"
    return media_plan_history.approve_comment if media_plan_history.aasm_state == "approved"

    ""
  end

  def media_plan_history_modified_status(media_plan_history)
    return "Modified; " if (media_plan_history.aasm_state == "in_review" || media_plan_history.aasm_state == "approved") && media_plan_history.media_plan_output.modified_by_user_at
    return "Modified; " if ["approved", "rejected"].include?(media_plan_history.aasm_state) && media_plan_history.media_plan_output.modified_by_reviewer_at

    ""
  end

  def filter_options(media_plan, filters, target_field_name)
    return [] if target_field_name.blank?

    combined_filters = filters.merge(
      campaign_objective_id: media_plan.media_brief.campaign_objective_id,
      campaign_initiative_id: media_plan.media_brief.campaign_initiative_id
    )

    MasterRelationship.filter_options(combined_filters, target_field_name).pluck(:label, :id)
  end

  def has_errors_on_rows?(media_plan)
    media_plan.media_plan_output.errors.any?
  end

  def update_button_class(media_plan)
    has_errors_on_rows?(media_plan) ? "" : "d-none"
  end

  def approve_reject_button_class(media_plan)
    has_errors_on_rows?(media_plan) ? "d-none" : ""
  end
end
