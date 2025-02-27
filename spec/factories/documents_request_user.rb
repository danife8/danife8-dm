FactoryBot.define do
  factory :documents_request_user do
    association :user, factory: :user
    association :documents_request, factory: :documents_request
  end
end
