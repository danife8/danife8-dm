# Common behavior for mailers.
class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("EMAIL_FROM", "from@example.com")
  layout "mailer"
  prepend_view_path "app/views/mailers"
end
