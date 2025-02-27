class DocumentsRequestsController < ApplicationController
  include InheritedResource

  USER_PARAMS = %i[user_id first_name last_name phone_number email client_id].freeze
  REQUESTED_OPTIONS = DocumentsRequest::REQUESTED_OPTIONS.keys.index_with { %i[value completed] }.freeze

  before_action :filtered_documents_request_params, only: %i[create update]

  # POST /documents_request
  def create
    ActiveRecord::Base.transaction do
      user = Users::FindOrCreateUserService.new(current_user, @user_params).call
      @documents_request = DocumentsRequest.new(
        insertion_order: policy_scope(InsertionOrder).find(documents_request_params[:insertion_order_id]),
        sender: current_user,
        documents_requested: @documents_request_options
      )
      @documents_request.save!
      @documents_request.users << user
      redirect_to campaign_path(@documents_request.campaign), notice: "Documents request in process."
    end
  rescue => error
    Rails.logger.info("Documents Request Error: #{error}")
    redirect_to campaigns_path, alert: "There was a problem creating the Documents Request."
  end

  # PATCH /documents_requests/:id
  def update
    if @user_params.any?
      user = Users::FindOrCreateUserService.new(current_user, @user_params).call
      if resource&.users&.include?(user)
        DocumentsRequestMailer.send_reminder(resource, user).deliver_later
      else
        resource.users << user
      end
    end
    if @documents_request_options.any?
      resource.update!(documents_requested: @documents_request_options)
    end

    redirect_to documents_request_path(resource), notice: "Documents request updated."
  rescue => error
    Rails.logger.info("Documents Request Error: #{error}")
    redirect_to documents_path, alert: "There was a problem updating the Documents Request."
  end

  # POST /documents_request/:id/send_mailer
  def send_reminder
    user = policy_scope(User).find_by(id: params[:user_id])
    if user.presence
      DocumentsRequestMailer.send_reminder(resource, user).deliver_later
      render json: {success: true}
    else
      redirect_to campaign_path(resource.campaign), alert: "There was a problem sending the reminder."
    end
  end

  # GET /documents_request/:id
  def show
  end

  # GET /documents_request/:id/edit
  def edit
    collection = resource.documents.where(files_for: params[:files_for])
    self.collection = Kaminari.paginate_array(collection)
      .page(params[:page])
      .per(params[:per] || 10)
  end

  private

  def documents_request_params
    params.require(:documents_request).permit(:insertion_order_id, REQUESTED_OPTIONS, *USER_PARAMS)
  end

  def filtered_documents_request_params
    @user_params = documents_request_params.to_h.slice(*USER_PARAMS).compact_blank
    @documents_request_options = documents_request_params.to_h.slice(*REQUESTED_OPTIONS.keys)
  end

  def policy_model
    policy_scope(model)
  end
end
