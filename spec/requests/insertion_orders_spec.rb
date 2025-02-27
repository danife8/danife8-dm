describe "InsertionOrdersController", type: :request do
  let(:agency) { create(:agency) }
  let(:client) { create(:client, agency:) }
  let(:request_params) { {} }

  shared_examples_for "insertion_orders GET action" do
    context "when no user is logged in" do
      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is logged in" do
      let(:super_admin) { false }
      let(:user) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }

      before do
        sign_in(user)
        subject
      end

      context "when user is admin" do
        let(:user_role) { create(:admin_role) }

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

        it "responds with success" do
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
        let(:user_role) { create(:admin_role) }

        it "responds with success" do
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "GET /insertion_orders" do
    before do
      create_list(:campaign_channel, 5)
    end

    let(:super_admin) { false }
    let(:user) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
    let(:user_role) { create(:admin_role) }

    subject { get "/insertion_orders", params: request_params }

    it_behaves_like "insertion_orders GET action"

    context "when searching by query" do
      let(:query) { "needle" }
      let!(:media_plan) { create(:media_plan, client:) }
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

      it "shows insertion orders matching search query" do
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

      it "shows insertion orders matching the truly client_id" do
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
      let!(:media_plan) { create(:media_plan, client:) }
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

      it "shows insertion orders matching the truly client_ids" do
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

        allow(InsertionOrder).to receive(:order_by).with("title", "asc").and_call_original
        subject
      end

      it "should execute InsertionOrder.order_by with 'title' and 'asc'" do
        expect(InsertionOrder).to have_received(:order_by).with("title", "asc")
      end
    end

    context "when ordering by created_at" do
      before do
        create_list(:insertion_order, 5, client:)

        request_params[:sort] = "created_at.asc"
        sign_in(user)

        allow(InsertionOrder).to receive(:order_by).and_call_original
        subject
      end

      it "should execute InsertionOrder.order_by" do
        expect(InsertionOrder).to have_received(:order_by)
      end
    end

    context "when not ordered by created_at" do
      before do
        create_list(:insertion_order, 5, client:)

        request_params[:sort] = ""
        sign_in(user)

        allow(InsertionOrder).to receive(:order_by).and_call_original
        subject
      end

      it "should execute InsertionOrder.order_by" do
        expect(InsertionOrder).not_to have_received(:order_by)
      end
    end
  end
end
