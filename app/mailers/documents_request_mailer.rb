class DocumentsRequestMailer < ApplicationMailer
  def notify_user(documents_request, user)
    @documents_request = documents_request
    @user = user
    mail(
      to: @user.email,
      subject: "You have been requested to complete some documents for Campaign #{@documents_request.insertion_order.title}"
    )
  end

  def send_reminder(documents_request, user)
    @documents_request = documents_request
    @user = user
    mail(
      to: @user.email,
      subject: "Reminder: You have been requested to complete some documents for Campaign #{@documents_request.insertion_order.title}",
      template_name: "notify_user"
    )
  end

  def notify_document_completed(documents_request, requested_option)
    @documents_request = documents_request
    @requested_option = requested_option
    mail(
      to: documents_request.sender.email,
      subject: "Task completed in Campaign #{@documents_request.insertion_order.title}"
    )
  end
end
