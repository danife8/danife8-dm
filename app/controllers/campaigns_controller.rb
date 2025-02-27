class CampaignsController < ApplicationController
  include InheritedResource
  include Filterable

  before_action :set_campaign_resources, only: [:show]

  # GET /campaigns
  def index
  end

  # GET /campaigns/:id
  def show
    self.collection = Kaminari.paginate_array(@collection)
      .page(params[:page])
      .per(params[:per] || 10)
  end

  # GET /campaigns/:id/add_client_user
  def add_client_user
  end

  # GET /campaigns/:id/request_documents
  def request_documents
    authorize @documents_request = DocumentsRequest.build(documents_requested: DocumentsRequest::REQUESTED_OPTIONS)
  end

  # GET /campaigns/:id/edit_documents_request
  def edit_documents_request
    authorize @documents_request = resource.documents_request
    render :request_documents
  end

  private

  def set_campaign_resources
    @collection = [
      resource.insertion_order,
      resource.media_plan,
      resource.media_mix,
      resource.media_brief,
      resource.documents
    ].flatten
  end

  def policy_model
    super
  end
end
