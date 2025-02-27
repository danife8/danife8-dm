class GenerateMediaPlanPptJob < ApplicationJob
  queue_as :default

  def perform(media_plan_id, user_id)
    media_plan = MediaPlan.find(media_plan_id)
    file = MediaPlans::Presentation::Export.new(media_plan).call

    media_plan.ppt_file.attach(io: File.open(file.to_s), filename: "media-plan-#{media_plan.title.parameterize}-#{media_plan.id}.pptx")

    media_plan.save!

    MediaPlanMailer.pptx(media_plan_id, user_id).deliver_later
  end
end
