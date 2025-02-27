require "rails_helper"
require "rake"

# Sample data from staging DB
# <DocumentsRequest:0x00007f666e304748
#   id: 43,
#   insertion_order_id: 13,
#   sender_id: 12,
#   documents_requested: "{\"previous_campaign_data\":\"true\",\"sign_insertion_order\":\"true\"}",
#   created_at: Mon, 25 Nov 2024 14:22:39.107804000 UTC +00:00,
#   updated_at: Mon, 25 Nov 2024 14:22:39.107804000 UTC +00:00
#  >
#
#  after documents_requested is changed to jsonb you should get
#  value: true, in the previous_campaign_data and sign_insertion_order

RSpec.describe "documents_request:transform_documents_requested_json" do
  before(:all) do
    Rake.application.rake_require "tasks/documents_request"
    Rake::Task.define_task(:environment)
  end

  let(:task) { Rake::Task["documents_request:transform_documents_requested_json"] }

  before do
    create_list(:campaign_channel, 5)
    task.reenable
  end

  let(:agency) { create(:agency) }
  let(:client) { create(:client, agency:) }
  let(:request_params) { {} }

  let(:super_admin) { false }
  let(:user_role) { create(:admin_role) }
  let(:user) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
  let(:user_2) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
  let(:media_plan) { create(:media_plan, client:) }
  let(:insertion_order) { create(:insertion_order, media_plan:, client:) }
  let(:documents_requested) { {"previous_campaign_data" => "true", "sign_insertion_order" => "true"} }
  let(:documents_request) { create(:documents_request, insertion_order:, sender: user, users: [user_2]) }

  it "transforms documents_requested data correctly" do
    # In the DB, documents_requested should be a JSON string
    # Running the migration, will get you a hash with strings key and value

    # Bypassing setter method from DocumentsRequest model
    documents_request.update_column(:documents_requested, documents_requested)

    task.invoke

    expect(documents_request.reload.documents_requested).to eq({
      previous_campaign_data: {label: "Previous Campaign Data", completed: false, value: true},
      previous_customer_data: {label: "Previous customer data", completed: false, value: false},
      creative_assets: {label: "Creative Assets", completed: false, value: false},
      sign_insertion_order: {label: "Sign Insertion Order", completed: false, value: true}
    })
  end
end
