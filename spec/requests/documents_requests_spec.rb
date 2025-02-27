require "rails_helper"

describe "DocumentsRequestsController", type: :request do
  let(:agency) { create(:agency) }
  let(:client) { create(:client, agency:) }

  before do
    create_list(:campaign_channel, 5)
    create(:client_user_role)
  end

  let(:super_admin) { false }
  let(:user_role) { create(:admin_role) }
  let(:user) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
  let(:user_2) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
  let(:user_3) { create(:user, agency:, user_role:, aasm_state: "active", super_admin:) }
  let(:new_user_params) { {first_name: "John", last_name: "Doe", phone_number: "6155551212", email: "johndoe@example.com", client_id: client.id} }
  let(:media_plan) { create(:media_plan, client:) }
  let(:insertion_order) { create(:insertion_order, media_plan:, client:) }
  let(:campaign) { insertion_order.campaign }

  let(:agency_2) { create(:agency) }
  let(:client_2) { create(:client, agency: agency_2) }
  let(:user_client_2) { create(:user, agency: agency_2, user_role:, aasm_state: "active", super_admin:) }
  let(:media_plan_2) { create(:media_plan, client: client_2) }
  let(:insertion_order_2) { create(:insertion_order, media_plan: media_plan_2, client: client_2) }

  shared_examples "it creates the documents request and redirects to the campaign path" do
    it { expect(response).to redirect_to(campaign_path(campaign.id)) }
    it { expect(flash[:notice]).to eq("Documents request in process.") }
    it { expect(DocumentsRequest.count).to eq(1) }
  end

  shared_examples "it does not create the documents request and redirects to the campaign path" do
    it { expect(response).to redirect_to(campaigns_path) }
    it { expect(flash[:alert]).to eq("There was a problem creating the Documents Request.") }
    it { expect(DocumentsRequest.count).to eq(0) }
  end

  describe "GET /documents_requests/:id" do
    let(:documents_request) { create(:documents_request, insertion_order:, users: [user_2], sender: user) }
    subject { get "/documents_requests/#{documents_request.id}" }

    context "user without access" do
      before do
        sign_in(user_client_2)
        subject
      end
      it { expect(response).to have_http_status(:not_found) }
    end

    context "user sender with access" do
      before do
        sign_in(user)
        subject
      end
      it { expect(response.body).to include(ERB::Util.html_escape("Checklist | Campaign - #{insertion_order.title}")) }
    end

    context "user recipient with access" do
      before do
        sign_in(user_2)
        subject
      end
      it { expect(response.body).to include(ERB::Util.html_escape("Checklist | Campaign - #{insertion_order.title}")) }
    end
  end

  describe "GET /documents_requests/:id/upload_documents" do
    let(:documents_request) { create(:documents_request, insertion_order:, sender: user, users: [user_2]) }
    let(:files_for_param) { documents_request.documents_requested.keys.first }

    subject { get "/documents_requests/#{documents_request.id}/upload_documents", params: {files_for: files_for_param} }

    before do
      sign_in(user)
      subject
    end

    it "returns the hidden input for the files_for param" do
      expect(response.body).to include(
        "<input value=\"#{files_for_param}\" autocomplete=\"off\" type=\"hidden\" name=\"document[files_for]\" id=\"document_files_for\" />"
      )
    end
  end

  describe "GET /documents_requests/:id/edit" do
    let(:documents_request) { create(:documents_request, insertion_order:, users: [user_2], sender: user) }

    subject { get "/documents_requests/#{documents_request.id}/edit" }

    before do
      sign_in(user)
      subject
    end

    it "show the right title" do
      expect(response.body).to include(ERB::Util.html_escape("Checklist | Campaign - #{insertion_order.title}"))
    end
  end

  describe "POST /documents_requests" do
    subject { post "/documents_requests", params: request_params }

    context "with user_id" do
      before do
        sign_in(user)
        subject
      end

      context "with all request options" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              previous_campaign_data: {value: true},
              previous_customer_data: {value: true},
              creative_assets: {value: true},
              sign_insertion_order: {value: true},
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only previous_campaign_data" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              previous_campaign_data: {value: true},
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only previous_customer_data" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              previous_customer_data: {value: true},
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only creative_assets" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              creative_assets: {value: true},
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only sign_insertion_order" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              sign_insertion_order: {value: true},
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "without request options" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with insertion order out of scope" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order_2.id,
              user_id: user_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it does not create the documents request and redirects to the campaign path"
      end

      context "with new user parameters" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              user_id: user_2.id,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email]
            }
          }
        }
        it { expect(User.find_by(email: new_user_params[:email])).to eq(nil) }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with user parameters is sender user" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              user_id: user.id
            }
          }
        }
        it { expect(DocumentsRequest.last.users.last).to eq(DocumentsRequest.last.sender) }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with user out of scope" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              user_id: user_client_2.id,
              first_name: nil,
              last_name: nil,
              phone_number: nil,
              email: nil
            }
          }
        }
        it_behaves_like "it does not create the documents request and redirects to the campaign path"
      end
    end

    context "with new user parameters" do
      before do
        sign_in(user)
        subject
      end

      context "with all documents requested params" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              previous_campaign_data: {value: true},
              previous_customer_data: {value: true},
              creative_assets: {value: true},
              sign_insertion_order: {value: true},
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email],
              client_id: new_user_params[:client_id]
            }
          }
        }
        it { expect(User.last.email).to eq(new_user_params[:email]) }
        it { expect(User.last.user_role.name).to eq("client_user") }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only previous_campaign_data" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              previous_campaign_data: {value: true},
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email],
              client_id: new_user_params[:client_id]
            }
          }
        }
        it { expect(User.last.email).to eq(new_user_params[:email]) }
        it { expect(User.last.user_role.name).to eq("client_user") }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only previous_customer_data" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              previous_customer_data: {value: true},
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email],
              client_id: new_user_params[:client_id]
            }
          }
        }
        it { expect(User.last.email).to eq(new_user_params[:email]) }
        it { expect(User.last.user_role.name).to eq("client_user") }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only creative_assets" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              creative_assets: {value: true},
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email],
              client_id: new_user_params[:client_id]
            }
          }
        }
        it { expect(User.last.email).to eq(new_user_params[:email]) }
        it { expect(User.last.user_role.name).to eq("client_user") }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with only sign_insertion_order" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              sign_insertion_order: {value: true},
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email],
              client_id: new_user_params[:client_id]
            }
          }
        }
        it { expect(User.last.email).to eq(new_user_params[:email]) }
        it { expect(User.last.user_role.name).to eq("client_user") }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "without request options" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: new_user_params[:email],
              client_id: new_user_params[:client_id]
            }
          }
        }
        it { expect(User.last.email).to eq(new_user_params[:email]) }
        it { expect(User.last.user_role.name).to eq("client_user") }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end

      context "with already registered email" do
        let(:request_params) {
          {
            documents_request: {
              insertion_order_id: insertion_order.id,
              user_id: nil,
              first_name: new_user_params[:first_name],
              last_name: new_user_params[:last_name],
              phone_number: new_user_params[:phone_number],
              email: user_2.email
            }
          }
        }
        it { expect(User.last.first_name).not_to eq(new_user_params[:first_name]) }
        it { expect(DocumentsRequest.last.users.last).to eq(user_2) }
        it_behaves_like "it creates the documents request and redirects to the campaign path"
      end
    end
  end

  describe "POST /documents_requests/:id/send_reminder" do
    let(:documents_request) { create(:documents_request, insertion_order:, users: [user_2], sender: user) }
    subject { post "/documents_requests/#{documents_request.id}/send_reminder", params: request_params }

    before do
      sign_in(user)
    end

    Sidekiq::Testing.inline! do
      context "with valid user_id" do
        let(:mailer) { double("DocumentsRequestMailer") }
        let(:request_params) { {user_id: user_2.id} }

        before do
          allow(DocumentsRequestMailer).to receive(:send_reminder).and_return(mailer)
          allow(mailer).to receive(:deliver_later)
          subject
        end

        it "sends a notification email to the recipient" do
          expect(mailer).to have_received(:deliver_later)
        end
      end

      context "when the user is not found" do
        let(:request_params) { {user_id: "invalid_id"} }
        it "redirects to the campaign path with an alert" do
          subject
          expect(response).to redirect_to(campaign_path(documents_request.campaign))
          expect(flash[:alert]).to eq("There was a problem sending the reminder.")
        end
      end
    end
  end

  describe "PATCH /documents_requests/:id/" do
    let(:documents_request) { create(:documents_request, insertion_order:, users: [user_2], sender: user) }

    subject { patch "/documents_requests/#{documents_request.id}", params: request_params }

    before do
      sign_in(user_2)
    end

    context "with completed param" do
      let(:request_params) { {documents_request: {previous_campaign_data: {completed: true}}} }

      Sidekiq::Testing.inline! do
        context "when the completed option is true" do
          let(:mailer) { double("DocumentsRequestMailer") }

          before do
            allow(DocumentsRequestMailer).to receive(:notify_document_completed).and_return(mailer)
            allow(mailer).to receive(:deliver_later)
          end

          it "sends a notification email to the recipient" do
            subject
            expect(mailer).to have_received(:deliver_later)
          end

          it "marks the completed option as true" do
            subject
            expect(documents_request.reload.documents_requested[:previous_campaign_data][:completed]).to eq(true)
          end
        end
      end
    end

    context "with new documents_requested values" do
      let(:request_params) {
        {documents_request:
        {
          previous_campaign_data: {value: false},
          previous_customer_data: {value: false},
          creative_assets: {value: true},
          sign_insertion_order: {value: true}
        }}
      }

      it "updates the documents_requested values" do
        subject
        expect(documents_request.reload.documents_requested[:previous_campaign_data][:value]).to eq(false)
        expect(documents_request.reload.documents_requested[:previous_customer_data][:value]).to eq(false)
        expect(documents_request.reload.documents_requested[:creative_assets][:value]).to eq(true)
        expect(documents_request.reload.documents_requested[:sign_insertion_order][:value]).to eq(true)
      end
    end

    context "with user id" do
      let(:request_params) { {documents_request: {user_id: user_3.id}} }

      it "adds the user to the documents request" do
        subject
        expect(documents_request.reload.users.count).to eq(2)
      end
    end

    Sidekiq::Testing.inline! do
      context "with user already added" do
        let(:request_params) { {documents_request: {user_id: user_2.id}} }
        let(:mailer) { double("DocumentsRequestMailer") }

        before do
          allow(DocumentsRequestMailer).to receive(:send_reminder).and_return(mailer)
          allow(mailer).to receive(:deliver_later)
        end

        it "does not add the user to the documents request" do
          subject
          expect(documents_request.reload.users.count).to eq(1)
        end

        it "sends a reminder email to the user" do
          subject
          expect(mailer).to have_received(:deliver_later)
        end

        it "redirect the user to the documents_request path" do
          subject
          expect(response).to redirect_to(documents_request_path(documents_request))
        end
      end
    end

    context "with new user params" do
      let(:request_params) {
        {
          documents_request: {
            user_id: nil,
            first_name: new_user_params[:first_name],
            last_name: new_user_params[:last_name],
            phone_number: new_user_params[:phone_number],
            email: new_user_params[:email],
            client_id: new_user_params[:client_id]
          }
        }
      }

      it "creates the new user and add it to the documents_request" do
        subject
        expect(User.last.first_name).to eq(new_user_params[:first_name])
        expect(User.last.user_role.name).to eq("client_user")
        expect(documents_request.reload.users.last).to eq(User.last)
      end
    end
  end
end
