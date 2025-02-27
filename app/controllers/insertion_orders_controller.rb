class InsertionOrdersController < ApplicationController
  include InheritedResource
  include Filterable

  def show
  end

  def serve_pdf
    redirect_to rails_blob_path(resource.signature_request&.unsigned_document, disposition: "inline")
  end

  def policy_model
    super # Ensure that method definitions from all included concerns are respected
  end
end
