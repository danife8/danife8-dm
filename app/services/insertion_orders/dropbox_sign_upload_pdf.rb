module InsertionOrders
  require "dropbox-sign"

  class DropboxSignUploadPdf
    def initialize(file, io)
      @api = Dropbox::Sign::SignatureRequestApi.new(Dropbox::Sign::ApiClient.new)
      @file = file
      @io = io
    end

    attr_reader :api, :file, :io

    def call
      creator_signer = create_signer(io.media_plan.creator.full_name, io.media_plan.creator.email, 0)
      reviewer_signer = create_signer(io.media_plan.reviewer.full_name, io.media_plan.reviewer.email, 1)
      data = create_data([creator_signer, reviewer_signer], [file])
      api.signature_request_send(data)
    end

    private

    def create_signer(name, email_address, order)
      Dropbox::Sign::SubSignatureRequestSigner.new(
        email_address:,
        name:,
        order:
      )
    end

    def create_data(signers, files)
      Dropbox::Sign::SignatureRequestCreateEmbeddedRequest.new(
        client_id: ENV.fetch("DROPBOX_SIGN_CLIENT_ID", "ABC123"),
        title: io.title,
        subject: "IO ##{io.id} Ready to Sign",
        message: "Please Review and Sign this Document",
        signers:,
        files:,
        metadata: {insertion_order_id: io.id},
        test_mode:
      )
    end

    def test_mode
      ENV.fetch("DROPBOX_SIGN_TEST_MODE", "true").downcase == "true"
    end
  end
end
