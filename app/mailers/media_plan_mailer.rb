class MediaPlanMailer < ApplicationMailer
  helper MediaPlanHelper

  def review_notification(id)
    media_plan = MediaPlan.find(id)
    reviewers = UserRole.find_by(name: "reviewer").users.where(agency: media_plan.agency).pluck(:email)

    @media_plan_id = media_plan.id
    mail to: reviewers, subject: "A new Media Plan is ready to review"
  end

  def changed_status(id)
    @media_plan = MediaPlan.find(id)

    mail to: @media_plan.creator.email, subject: "A Media Plan's status has changed."
  end

  def approval_needed(id)
    @media_plan = MediaPlan.find(id)

    mail to: @media_plan.creator.email, subject: "Your approval is required"
  end

  def user_changed_status(id)
    @media_plan = MediaPlan.find(id)
    @status = if @media_plan.user_approved?
      "Approved"
    elsif @media_plan.user_rejected?
      "Rejected"
    end

    mail to: @media_plan.reviewer.email, subject: "The Media Plan was #{@status}"
  end

  def pptx(media_plan_id, user_id)
    media_plan = MediaPlan.find(media_plan_id)

    @ppt = url_for(media_plan.ppt_file)
    user = User.find(user_id)
    @full_name = user.full_name
    mail to: user.email, subject: "Your Media Plan Presentation is ready!"
  end
end
