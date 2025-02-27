class DocumentsRequest < ApplicationRecord
  ## CONSTANTS
  REQUESTED_OPTIONS = {
    previous_campaign_data: {label: "Previous Campaign Data", completed: false, value: false},
    previous_customer_data: {label: "Previous customer data", completed: false, value: false},
    creative_assets: {label: "Creative Assets", completed: false, value: false},
    sign_insertion_order: {label: "Sign Insertion Order", completed: false, value: false}
  }.freeze

  ## ASSOCIATIONS
  belongs_to :insertion_order
  belongs_to :sender, class_name: "User"
  has_many :documents, through: :insertion_order
  has_many :documents_request_users, dependent: :destroy
  has_many :users, through: :documents_request_users
  has_one :campaign, through: :insertion_order

  ## CALLBACKS
  before_update :set_completed_status

  ## VALIDATIONS
  validates :documents_requested, presence: true

  ## CLASS METHODS
  def has_files_for?(files_for_value)
    documents.exists?(files_for: files_for_value)
  end

  def documents_requested=(requested_params)
    unless requested_params.presence
      self[:documents_requested] = DocumentsRequest::REQUESTED_OPTIONS.deep_dup
      return
    end
    requested_params = requested_params.deep_symbolize_keys
    current_data = self[:documents_requested]&.deep_symbolize_keys || DocumentsRequest::REQUESTED_OPTIONS.deep_dup
    requested_params.each do |key, value|
      current_data[key][:value] = ActiveModel::Type::Boolean.new.cast(value[:value]) if value[:value].presence
      if value[:completed].presence
        current_data[key][:completed] = ActiveModel::Type::Boolean.new.cast(value[:completed])
        notify_document_completed(self, current_data[key]) if current_data[key][:completed]
      end
    end

    self[:documents_requested] = current_data
  end

  def documents_requested
    self[:documents_requested].deep_symbolize_keys
  end

  def notify_document_completed(documents_request, requested_option)
    DocumentsRequestMailer.notify_document_completed(documents_request, requested_option).deliver_later
  end

  def only_documents_required
    documents_requested.select { |key, value| value[:value] }
  end

  private

  def set_completed_status
    self.completed = only_documents_required.all? { |key, value| value[:completed] == true }
  end
end
