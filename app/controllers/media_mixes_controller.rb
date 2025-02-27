class MediaMixesController < ApplicationController
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.presentationml.presentation".freeze
  DISPOSITION = "attachment".freeze
  FILENAME = "media_mix_presentation.pptx".freeze

  include InheritedResource
  include Filterable

  expose :media_brief, -> { MediaBrief.find(params[:media_brief_id]) if params[:media_brief_id].present? }
  expose :client, -> { media_brief.client if media_brief.present? }

  def create
    create! do
      result = resource.generate_media_output
      flash[:alert] = result[:errors].join(", ") if result[:error]

      redirect_to media_mix_path(resource)
    end
  end

  def update
    update! do
      redirect_to media_mix_path(resource)
    end
  end

  def restore_version
    RestoreVersion.new(params[:version_id]).call
    redirect_to media_mix_path(resource), notice: "Media Mix version successfully restored."
  rescue => error
    redirect_back fallback_location: get_path(:index), alert: error
  end

  def destroy
    destroy! do |deleted|
      redirect_to media_mixes_path,
        notice: deleted ? "Media Mix was successfully archived." : "There was a problem archiving the Media Mix."
    end
  end

  def download_ppt
    current_user.export_logs.create!(resource:, title: resource.title, exported_at: Time.zone.now)
    GenerateMediaMixPptJob.perform_later(resource.id, current_user.id)

    redirect_back fallback_location: get_path(:index), notice: "Your Presentation has been emailed and will arrive shortly!"
  end

  protected

  def filter_params
    params.fetch(:filter, {}).permit(:q, :client_id, client_ids: {}, aasm_states: {})
  end

  def policy_model
    scope = super.joins(:media_brief)

    if filter_params[:client_id].present?
      scope = scope.by_client_id(filter_params[:client_id])
    end

    scope
  end

  # @return [ActionController::Parameters] permitted client params
  def permitted_params
    params.require(:media_mix).permit(
      policy(resource).permitted_params
    )
  end
end
