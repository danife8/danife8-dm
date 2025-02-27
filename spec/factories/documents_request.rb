FactoryBot.define do
  factory :documents_request do
    association :sender, factory: :user
    association :insertion_order, factory: :insertion_order
    completed { false }
    documents_requested {
      {
        previous_campaign_data: {label: "Previous Campaign Data", completed: false, value: true},
        previous_customer_data: {label: "Previous customer data", completed: false, value: true},
        creative_assets: {label: "Creative Assets", completed: false, value: true},
        sign_insertion_order: {label: "Sign Insertion Order", completed: false, value: true}
      }
    }

    transient do
      users { [] }
    end

    after(:create) do |documents_request, evaluator|
      evaluator.users.each do |user|
        documents_request.users << user
      end
    end

    trait :with_valid_documents_requested do
      documents_requested {
        {
          previous_campaign_data: {label: "Previous Campaign Data", completed: true, value: true},
          previous_customer_data: {label: "Previous customer data", completed: false, value: true},
          creative_assets: {label: "Creative Assets", completed: false, value: false},
          sign_insertion_order: {label: "Sign Insertion Order", completed: false, value: false}
        }
      }
    end

    trait :with_completed_documents_requested do
      documents_requested {
        {
          previous_campaign_data: {label: "Previous Campaign Data", completed: true, value: true},
          previous_customer_data: {label: "Previous customer data", completed: true, value: true},
          creative_assets: {label: "Creative Assets", completed: false, value: false},
          sign_insertion_order: {label: "Sign Insertion Order", completed: false, value: false}
        }
      }
      completed { true }
    end

    trait :with_user do
      users { [FactoryBot.create(:user)] }
    end

    trait :with_invalid_documents_requested do
      documents_requested { {previous_campaign_data: "false"}.to_json }
    end

    trait :with_blank_documents_requested do
      documents_requested { "" }
    end
  end
end
