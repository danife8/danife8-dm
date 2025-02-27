class DocumentsRequestUser < ApplicationRecord
  ## ASSOCIATIONS
  belongs_to :documents_request
  belongs_to :user

  ## VALIDATIONS
  validates :user_id, uniqueness: {scope: :documents_request_id}

  ## CALLBACKS
  after_create :notify_recipient

  private

  def notify_recipient
    DocumentsRequestMailer.notify_user(documents_request, user).deliver_later
  end
end
