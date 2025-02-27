class SignatureRequestJob < ApplicationJob
  queue_as :default

  def perform(callback_data)
    callback_event = Dropbox::Sign::EventCallbackRequest.init(callback_data)
    event_type = callback_event.event.event_type

    Rails.logger.info("Received Dropbox Sign event: #{event_type}")

    case event_type
    when "signature_request_all_signed"
      signature_request_all_signed(callback_event)
    when "signature_request_downloadable"
      signature_request_downloadable(callback_event)
    else
      Rails.logger.info "Unhandled event type: #{event_type}"
    end
  end

  private

  def signature_request_all_signed(callback_event)
    Rails.logger.info("Event type 'signature_request_all_signed' matched. Updating signature request status.")
    signature_request = find_signature_request(callback_event)

    return Rails.logger.error("No matching Signature request found.") unless signature_request.present?

    signature_request.complete!
    Rails.logger.info("Signature request status updated to 'completed' for signature request ID: #{signature_request.signature_request_id}")
  end

  def signature_request_downloadable(callback_event)
    Rails.logger.info("Event type 'signature_request_downloadable' matched. Fetching and attaching signed document.")
    signature_request = find_signature_request(callback_event)
    return Rails.logger.error("No matching Signature request found.") unless signature_request.present?

    signed_pdf_file = InsertionOrders::DropboxSignDownloadPdf.new(signature_request).call
    return Rails.logger.error("Failed to download signed document for Signature request ID: #{signature_request.signature_request_id}") unless signed_pdf_file

    begin
      signature_request.signed_document.attach(io: signed_pdf_file, filename: "signed_io_#{signature_request.insertion_order_id}.pdf")
      signature_request.save!
      Rails.logger.info("Signed document attached and saved for Signature request ID: #{signature_request.signature_request_id}")
    rescue
      Rails.logger.error("Failed to attach and save signed document for Signature request ID: #{signature_request.signature_request_id}")
    ensure
      signed_pdf_file.unlink # File removed from the file system
      signed_pdf_file.close # File descriptor released, the file cannot be read or written
    end
  end

  def find_signature_request(callback_event)
    signature_request_id = callback_event.signature_request.signature_request_id
    SignatureRequest.find_by(signature_request_id:)
  end
end
