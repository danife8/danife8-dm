namespace :documents_request do
  desc "Serialize documents_requested with all the options"
  task transform_documents_requested_json: :environment do
    DocumentsRequest.find_each do |documents_request|
      serialized_data = DocumentsRequest::REQUESTED_OPTIONS.deep_dup

      documents_request[:documents_requested].each do |key, value|
        if serialized_data.key?(key.to_sym)
          serialized_data[key.to_sym][:value] = ActiveModel::Type::Boolean.new.cast(value)
        end
      end
      documents_request[:documents_requested] = serialized_data
      documents_request.save!
    end
  end
end
