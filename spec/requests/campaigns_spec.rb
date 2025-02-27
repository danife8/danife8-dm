require "rails_helper"

describe "CampaignsController", type: :request do
  let(:agency) { create(:agency) }
  let(:client) { create(:client, agency:) }
  let(:request_params) { {} }

  before do
    create_list(:campaign_channel, 5)
  end

  let(:super_admin) { false }
  let(:user_role) { create(:admin_role) }
  let(:user) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
  let(:media_plan) { create(:media_plan, client:) }
  let(:insertion_order) { create(:insertion_order, media_plan:, client:) }
  let!(:documents_request) { create(:documents_request, insertion_order:, sender: user, users: [user_2]) }
  let(:campaign) { insertion_order.campaign }
  let(:valid_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf") }
  let(:invalid_file_type) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.xml"), "application/xml") }
  let(:large_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample_26mb.pdf"), "application/pdf") }
  let(:error_message_invalid_file_type) { "#{invalid_file_type.original_filename} error: Invalid file Content-Type" }
  let(:error_message_large_file) { "#{large_file.original_filename} error: Size should be less than 25MB" }

  let(:agency_2) { create(:agency) }
  let(:client_2) { create(:client, agency: agency_2) }
  let(:user_2) { create(:user, agency: agency_2, user_role:, aasm_state: "active", super_admin:) }

  shared_examples_for "campaigns GET action" do
    context "when no user is logged in" do
      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is logged in" do
      before do
        sign_in(user)
        subject
      end

      context "when user is admin" do
        it "responds with success" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when user is campaign_manager_role" do
        let(:user_role) { create(:campaign_manager_role) }

        it "responds with success" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when user is account_manager_role" do
        let(:user_role) { create(:account_manager_role) }

        it "redirects to created resource" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when user is a reviewer" do
        let(:user_role) { create(:reviewer_role) }

        it "responds with success" do
          expect(response).to have_http_status(:ok)
        end
      end

      context "when user is super admin" do
        let(:super_admin) { true }

        it "responds with success" do
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "GET /campaigns" do
    subject { get "/campaigns", params: request_params }

    it_behaves_like "campaigns GET action"

    context "when searching by query" do
      let(:query) { "needle" }

      let!(:matched_insertion_orders) do
        [
          create(:insertion_order, media_plan:, client:, title: "IO - #{query} Title 1"),
          create(:insertion_order, media_plan:, client:, title: "IO - #{query} Title 2")
        ]
      end
      let!(:unmatched_insertion_orders) do
        [
          create(:insertion_order, media_plan:, client:, title: "IO - Title 3"),
          create(:insertion_order, media_plan:, client:, title: "IO - Title 4")
        ]
      end

      before do
        request_params[:filter] = {
          q: query
        }
        sign_in(user)
        subject
      end

      it "shows campaigns matching search query" do
        matched_insertion_orders.each do |io|
          expect(response.body).to include(ERB::Util.html_escape(io.title))
        end
        unmatched_insertion_orders.each do |io|
          expect(response.body).to_not include(ERB::Util.html_escape(io.title))
        end
      end
    end

    context "when filtering by one client_id" do
      let!(:client_2) { create(:client, agency: client.agency) }
      let!(:media_plan) { create(:media_plan, client:) }
      let!(:matched_insertion_orders) do
        [
          create(:insertion_order, media_plan:, client:),
          create(:insertion_order, media_plan:, client:)
        ]
      end
      let!(:unmatched_insertion_orders) do
        [
          create(:insertion_order, media_plan:, client: client_2),
          create(:insertion_order, media_plan:, client: client_2)
        ]
      end

      before do
        request_params[:filter] = {
          client_ids: {
            "#{client.id}": "true",
            "#{client_2.id}": "false"
          }
        }
        sign_in(user)
        subject
      end

      it "shows campaigns matching the truly client_id" do
        matched_insertion_orders.each do |io|
          expect(response.body).to include(ERB::Util.html_escape(io.title))
        end
        unmatched_insertion_orders.each do |io|
          expect(response.body).not_to include(ERB::Util.html_escape(io.title))
        end
      end
    end

    context "when filtering by multiple client_ids" do
      let!(:client_2) { create(:client, agency: client.agency) }
      let!(:matched_insertion_orders) do
        [
          create(:insertion_order, media_plan:, client:),
          create(:insertion_order, media_plan:, client:),
          create(:insertion_order, media_plan:, client: client_2),
          create(:insertion_order, media_plan:, client: client_2)
        ]
      end

      before do
        request_params[:filter] = {
          client_ids: {
            "#{client.id}": "true",
            "#{client_2.id}": "true"
          }
        }
        sign_in(user)
        subject
      end

      it "shows campaigns matching the truly client_ids" do
        matched_insertion_orders.each do |io|
          expect(response.body).to include(ERB::Util.html_escape(io.title))
        end
      end
    end

    context "when ordering by title" do
      before do
        create_list(:insertion_order, 5, client:)

        request_params[:sort] = "title.asc"
        sign_in(user)

        allow(Campaign).to receive(:order_by).with("title", "asc").and_call_original
        subject
      end

      it "should execute Campaign.order_by with 'title' and 'asc'" do
        expect(Campaign).to have_received(:order_by).with("title", "asc")
      end
    end

    context "when ordering by created_at" do
      before do
        create_list(:insertion_order, 5, client:)

        request_params[:sort] = "created_at.asc"
        sign_in(user)

        allow(Campaign).to receive(:order_by).and_call_original
        subject
      end

      it "should execute Campaign.order_by" do
        expect(Campaign).to have_received(:order_by)
      end
    end

    context "when not ordered by created_at" do
      before do
        create_list(:insertion_order, 5, client:)

        request_params[:sort] = ""
        sign_in(user)

        allow(Campaign).to receive(:order_by).and_call_original
        subject
      end

      it "should execute Campaign.order_by" do
        expect(Campaign).not_to have_received(:order_by)
      end
    end
  end

  describe "GET /campaigns/:id" do
    subject { get "/campaigns/#{campaign.id}" }

    it_behaves_like "campaigns GET action"

    context "with all campaign campaigns" do
      before do
        sign_in(user)
        subject
      end

      it "should show the campaign" do
        expect(response.body).to include(ERB::Util.html_escape(campaign.insertion_order.title))
      end

      it "should show the media_plan from the campaign" do
        expect(response.body).to include(ERB::Util.html_escape(campaign.media_plan.title))
      end

      it "should show the media_mix from the campaign" do
        expect(response.body).to include(ERB::Util.html_escape(campaign.media_mix.title))
      end

      it "should show the media_brief from the campaign" do
        expect(response.body).to include(ERB::Util.html_escape(campaign.media_brief.title))
      end
    end

    context "when user is from other agency" do
      before do
        sign_in(user_2)
        subject
      end

      it "returns 404" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /campaigns/:id/upload_documents" do
    subject { get "/campaigns/#{campaign.id}/upload_documents" }
    it_behaves_like "campaigns GET action"

    it "render drag_and_drop form" do
      sign_in(user)
      subject
      expect(response.body).to include(ERB::Util.html_escape("Drag and Drop Add-on"))
    end
  end

  describe "GET /campaigns/:id/request_documents" do
    subject { get "/campaigns/#{campaign.id}/request_documents" }
    before do
      sign_in(user)
      subject
    end

    it "render request_documents page" do
      expect(response.body).to include(ERB::Util.html_escape("Request Documents | Campaign - #{campaign.insertion_order.title}"))
    end
  end

  describe "GET /campaigns/:id/add_client_user" do
    subject { get "/campaigns/#{campaign.id}/add_client_user" }
    before do
      sign_in(user)
      subject
    end

    it "render add_client_user page" do
      expect(response.body).to include(ERB::Util.html_escape("Select or Add Client User | Campaign - #{campaign.insertion_order.title}"))
    end
  end
end
