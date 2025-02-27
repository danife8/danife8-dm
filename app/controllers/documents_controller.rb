class DocumentsController < ApplicationController
  include InheritedResource

  before_action :set_campaign, only: %i[upload_documents create]

  # GET /campaigns/:id/upload_documents
  # GET /documents_requests/:id/upload_documents
  def upload_documents
    @document = Document.new
  end

  # POST /documents/create
  def create
    campaign = policy_scope(Campaign).find(params[:campaign_id])
    if Document::FILES_FOR.include?(document_params[:files_for])
      files_for = document_params[:files_for]
      redirect_path = edit_documents_request_path(campaign.documents_request, files_for: files_for)
    else
      files_for = nil
      redirect_path = campaign_path(campaign)
    end

    files = document_params[:files].compact_blank
    return redirect_to redirect_path, alert: "Please select a file to upload." if files.blank?

    @errors = []
    files.each do |file|
      document = Document.new(
        insertion_order: campaign.insertion_order,
        files_for: files_for
      )
      document.file.attach(file)
      unless document.save
        @errors << document.errors.full_messages.join(", ")
      end
    end

    if @errors.empty?
      redirect_to redirect_path, notice: "Documents uploaded successfully."
    elsif files.size > @errors.size
      redirect_to redirect_path, alert: "Some files could not be saved."
    else
      render :upload_documents, errors: @errors, status: :unprocessable_entity
    end
  end

  # DELETE /documents/:id
  def destroy
    redirect_path = params[:destroy_redirection_path] || campaign_path(resource.campaign)
    if resource.destroy
      redirect_to redirect_path, notice: "Document deleted successfully."
    else
      redirect_to request.referrer, alert: "Something went wrong. Try again later."
    end
  end

  private

  def document_params
    params.require(:document).permit(:files_for, files: [])
  end

  def set_campaign
    if params[:campaign_id].present?
      @campaign = policy_scope(Campaign).find_by(id: params[:campaign_id])
    elsif params[:documents_request_id].present?
      @campaign = policy_scope(DocumentsRequest).find_by(id: params[:documents_request_id])&.campaign
    end
  end
end
