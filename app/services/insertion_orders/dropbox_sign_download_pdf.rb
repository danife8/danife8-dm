module InsertionOrders
  require "dropbox-sign"
  require "fileutils"
  require "tempfile"

  class DropboxSignDownloadPdf
    def initialize(signature_request)
      @api = Dropbox::Sign::SignatureRequestApi.new(Dropbox::Sign::ApiClient.new)
      @signature_request = signature_request
    end

    attr_reader :api, :signature_request

    def call
      fetch_pdf
    rescue Dropbox::Sign::ApiError => e
      Rails.logger.error("Error downloading PDF: #{e.message}")
      nil
    end

    private

    def fetch_pdf
      response = api.signature_request_files(signature_request.signature_request_id)
      save_to_tmp(response)
    end

    def save_to_tmp(tempfile)
      file = Tempfile.new(["signed_io_#{signature_request.insertion_order_id}", ".pdf"], Rails.root.join("tmp"))
      file.binmode
      File.open(tempfile.path, "rb") do |f|
        file.write(f.read)
      end
      file.rewind

      file
    end
  end
end
