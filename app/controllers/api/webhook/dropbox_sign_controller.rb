module Api
  module Webhook
    class DropboxSignController < ApiController
      # POST /api/webhook/dropbox_sign
      def create
        callback_data = JSON.parse(params[:json], symbolize_names: true)
        callback_event = Dropbox::Sign::EventCallbackRequest.init(callback_data)

        if valid_callback?(callback_event)
          SignatureRequestJob.perform_later(callback_data)

          render plain: "Hello API Event Received"
        else
          render plain: "Invalid Event", status: :forbidden
        end
      rescue JSON::ParserError
        render plain: "Bad Request", status: :bad_request
      end

      private

      def valid_callback?(callback_event)
        Dropbox::Sign::EventCallbackHelper.is_valid(ENV.fetch("DROPBOX_SIGN_API_KEY", "ABC123"), callback_event)
      end
    end
  end
end
