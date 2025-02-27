# spec/factories/insertion_orders.rb

FactoryBot.define do
  factory :insertion_order do
    sequence(:title) { |n| "IO #{n}" }
    association :client, factory: :client
    association :media_plan, factory: :media_plan

    after(:create) do |insertion_order|
      create(:signature_request, insertion_order: insertion_order, aasm_state: :unsigned)
    end
  end
end
