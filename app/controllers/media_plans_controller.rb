class MediaPlansController < ApplicationController
  include InheritedResource
  include Filterable

  expose :media_output, -> { resource.media_mix.media_output }
  expose :engine do
    media_output.present? ? media_output.channel_strategies.last : MediaOutputChannelStrategy.new
  end
  expose :clients, -> { policy_scope(Client).ordered }
  expose :reviewers, -> { current_user.agency.users.reviewers }
  expose :keywords, -> { MediaPlans::KeywordGenerator.new(resource).call }
  expose :media_mix, -> { params[:media_mix_id] ? MediaMix.find(params[:media_mix_id]) : nil }
  expose :client, -> { media_mix&.client }
  expose :media_brief, -> { resource.media_brief }
  expose :media_mixes, -> { client.present? ? MediaMix.by_client_ids(client.id) : [] }
  expose :audience_overlays, -> { MediaPlans::AudienceOverlay.new(resource).call }

  def create
    create! do
      result = resource.generate_media_plan_output
      flash[:alert] = result[:errors].join(", ") if result[:error]

      redirect_to edit_media_plan_path(resource)
    end
  end

  def export
    current_user.export_logs.create!(resource:, title: resource.title, exported_at: Time.zone.now)
    GenerateMediaPlanPptJob.perform_later(resource.id, current_user.id)

    redirect_back fallback_location: get_path(:index), notice: "Your Presentation has been emailed and will arrive shortly!"
  end

  def restore_version
    RestoreVersion.new(params[:version_id]).call
    redirect_to versions_media_plan_path, notice: build_success_message("restored")
  rescue => error
    redirect_back fallback_location: versions_media_plan_path, alert: error
  end

  def in_queue
    self.collection = collection.unscope(:order).in_queue_first unless sort_params.present?
  end

  def my_reviews
    self.collection = collection.where(reviewer: current_user)
  end

  def approvals
    self.collection = if current_user.reviewer?
      collection.where(reviewer: current_user, aasm_state: :approved)
    else
      collection.where(creator: current_user, aasm_state: :approved)
    end
  end

  def versions
  end

  def in_review
    self.collection = collection.where(creator: current_user, aasm_state: :in_review)
  end

  def show
  end

  def reviewer_assign
    resource.reviewer_assigned_at = Time.zone.now
    resource.reviewer = current_user.agency.users.reviewers.find(params[:media_plan][:reviewer_id])
    resource.reviewer_assign if resource.in_review?

    if resource.save
      redirect_back fallback_location: in_queue_media_plans_path, notice: build_success_message("assigned")
    else
      redirect_back fallback_location: in_queue_media_plans_path, alert: build_error_message("assigning")
    end
  end

  def update
    authorize resource, :"#{params[:media_plan][:action]}?"
    result = MediaPlans::UpdateMediaPlanState.new(resource, params, current_user).call

    if result[:success]
      redirect_to update_path, notice: result[:message]
    else
      flash[:alert] = result[:message]
      render :edit, status: 422
    end
  end

  def destroy
    destroy! do |deleted|
      redirect_to media_plans_path,
        notice: deleted ? build_success_message("archived") : build_error_message("archiving")
    end
  end

  protected

  def update_path
    (params[:media_plan][:action] == "update") ? edit_media_plan_path(resource) : media_plan_path(resource)
  end

  def policy_model
    super # Ensure that method definitions from all included concerns are respected
  end

  def permitted_params
    params.require(:media_plan).permit(
      policy(resource).permitted_params
    ).merge(creator: current_user)
  end

  def build_error_message(ongoing_action)
    "There was a problem #{ongoing_action} the Media Plan. Please try again."
  end

  def build_success_message(past_action)
    "The Media Plan was successfully #{past_action}."
  end
end
