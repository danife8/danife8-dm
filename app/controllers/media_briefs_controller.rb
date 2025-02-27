# Resources to manage media briefs.
class MediaBriefsController < ApplicationController
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.presentationml.presentation".freeze
  DISPOSITION = "attachment".freeze
  FILENAME = "media_brief_presentation.pptx".freeze

  include InheritedResource
  include Filterable

  # PATCH/PUT /media_brief_builders/:id
  def update
    update! do
      redirect_to [:edit, resource, step: params[:back_to_step]]
    end
  end

  def destroy
    destroy! do |deleted|
      redirect_to media_briefs_path,
        notice: deleted ? "Media Brief was successfully archived." : "There was a problem archiving the Media Brief"
    end
  end

  # GET /media_briefs/:id/download_ppt
  def download_ppt
    ppt_data = MediaBriefs::SharePpt.new(resource).call
    send_data ppt_data, type: CONTENT_TYPE, disposition: DISPOSITION, filename: FILENAME
  end

  def restore_version
    RestoreVersion.new(params[:version_id]).call
    redirect_to media_brief_path(resource), notice: "Media Brief version successfully restored."
  rescue => error
    redirect_back fallback_location: get_path(:index), alert: error
  end

  protected

  # @return [ActionController::Parameters] permitted media brief filter params
  def filter_params
    params.fetch(:filter, {}).permit(:q, :client_id, client_ids: {}, aasm_states: {})
  end

  def policy_model
    scope = super

    if filter_params[:client_id].present?
      scope = scope.by_client_id(filter_params[:client_id])
    end

    scope
  end

  def permitted_params
    params.require(:media_brief).permit(
      policy(resource).send(:"step#{params[:step]}_permitted_params").reject { |param| param == :current_step }
    )
  end
end
