class DocumentsRequestReminderJob < ApplicationJob
  queue_as :default

  def perform
    DocumentsRequest.where("completed IS FALSE AND updated_at < ?", 7.days.ago).includes(:users).find_each do |documents_request|
      documents_request.users.each do |user|
        DocumentsRequestMailer.send_reminder(documents_request, user).deliver_later
      end
    end
  end
end
