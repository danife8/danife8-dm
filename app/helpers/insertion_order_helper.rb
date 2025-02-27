module InsertionOrderHelper
  def pdf_exists?(insertion_order)
    insertion_order.signature_request&.unsigned_document.present?
  end
end
