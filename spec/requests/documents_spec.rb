require "rails_helper"

describe "DocumentsController", type: :request do
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

  shared_examples_for "documents POST action" do
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
        it "redirects to created resource" do
          expect(response).to redirect_to(campaign_path(campaign.id))
        end
      end

      context "when user is campaign_manager_role" do
        let(:user_role) { create(:campaign_manager_role) }

        it "redirects to created resource" do
          expect(response).to redirect_to(campaign_path(campaign.id))
        end
      end

      context "when user is account_manager_role" do
        let(:user_role) { create(:account_manager_role) }

        it "redirects to created resource" do
          expect(response).to redirect_to(campaign_path(campaign.id))
        end
      end

      context "when user is reviewer_role" do
        let(:user_role) { create(:reviewer_role) }

        it "redirects to created resource" do
          expect(response).to redirect_to(campaign_path(campaign.id))
        end
      end

      context "when user is super admin" do
        let(:super_admin) { true }

        it "redirects to created resource" do
          expect(response).to redirect_to(campaign_path(campaign.id))
        end
      end
    end
  end

  describe "POST /campaigns/:id/documents" do
    subject { post "/campaigns/#{campaign.id}/documents", params: request_params }

    context "without files" do
      let(:request_params) { {document: {files: []}} }
      before do
        sign_in(user)
        subject
      end

      it "redirects to the campaign documents path" do
        expect(response).to redirect_to(campaign_path(campaign.id))
        expect(flash[:alert]).to eq("Please select a file to upload.")
        expect(Document.count).to eq(0)
      end
    end

    context "with files from campaign uploader" do
      let(:request_params) { {document: {files: [valid_file]}} }
      it_behaves_like "documents POST action"

      context "with valid files" do
        before do
          sign_in(user)
          subject
        end

        it "saves the document and redirects to the campaign documents path" do
          expect(response).to redirect_to(campaign_path(campaign.id))
          expect(flash[:notice]).to eq("Documents uploaded successfully.")
          expect(Document.count).to eq(1)
        end

        context "with multiple valid files" do
          let(:request_params) { {document: {files: [valid_file, valid_file]}} }

          it "saves multiple documents and redirects to the campaign documents path" do
            expect(response).to redirect_to(campaign_path(campaign.id))
            expect(flash[:notice]).to eq("Documents uploaded successfully.")
            expect(Document.count).to eq(2)
          end
        end

        context "with valid and invalid files" do
          let(:request_params) { {document: {files: [valid_file, invalid_file_type]}} }

          it "saves multiple documents and redirects to the campaign documents path" do
            expect(response).to redirect_to(campaign_path(campaign.id))
            expect(flash[:alert]).to eq("Some files could not be saved.")
            expect(Document.count).to eq(1)
          end
        end

        context "with multiple invalid files" do
          let(:request_params) { {document: {files: [large_file, invalid_file_type]}} }

          it "saves multiple documents and redirects to the campaign documents path" do
            expect(response).to have_http_status(:unprocessable_entity)
            expect(response.body).to include(ERB::Util.html_escape(error_message_large_file))
            expect(response.body).to include(ERB::Util.html_escape(error_message_invalid_file_type))
            expect(Document.count).to eq(0)
          end
        end
      end

      context "with invalid file type" do
        let(:request_params) { {document: {files: [invalid_file_type]}} }

        before do
          sign_in(user)
          subject
        end

        it "does not save the document and re-renders the upload template with errors" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include(ERB::Util.html_escape(error_message_invalid_file_type))
          expect(Document.count).to eq(0)
        end
      end

      context "with a file larger than 25MB" do
        let(:request_params) { {document: {files: [large_file]}} }
        before do
          sign_in(user)
          subject
        end

        it "does not save the document and re-renders the upload template with errors" do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include(ERB::Util.html_escape(error_message_large_file))
          expect(Document.count).to eq(0)
        end
      end
    end

    context "with files from documents_request uploader" do
      before do
        sign_in(user)
        subject
      end

      context "with previous_campaing_data" do
        let(:request_params) { {document: {files: [valid_file, valid_file], files_for: "previous_campaign_data"}} }

        it "saves the document and redirects to the documents_request/:id/edit?files_for=previous_campaign_data path" do
          expect(response).to redirect_to(edit_documents_request_path(insertion_order.documents_request, files_for: "previous_campaign_data"))
          expect(flash[:notice]).to eq("Documents uploaded successfully.")
          expect(insertion_order.previous_campaign_data_documents.count).to eq(2)
        end
      end

      context "with previous_customer_data" do
        let(:request_params) { {document: {files: [valid_file, valid_file], files_for: "previous_customer_data"}} }

        it "saves the document and redirects to the documents_request/:id/edit?files_for=previous_customer_data path" do
          expect(response).to redirect_to(edit_documents_request_path(documents_request, files_for: "previous_customer_data"))
          expect(flash[:notice]).to eq("Documents uploaded successfully.")
          expect(insertion_order.previous_customer_data_documents.count).to eq(2)
        end
      end

      context "with creative_assets" do
        let(:request_params) { {document: {files: [valid_file, valid_file], files_for: "creative_assets"}} }

        it "saves the document and redirects to the documents_request/:id/edit?files_for=creative_assets path" do
          expect(response).to redirect_to(edit_documents_request_path(insertion_order.documents_request, files_for: "creative_assets"))
          expect(flash[:notice]).to eq("Documents uploaded successfully.")
          expect(insertion_order.creative_assets_documents.count).to eq(2)
        end
      end

      context "with invalid files_for param" do
        let(:request_params) { {document: {files: [valid_file, valid_file], files_for: "sign_insertion_order"}} }

        it "saves the document and redirects to the campaigns/:id path" do
          expect(response).to redirect_to(campaign_path(campaign.id))
          expect(flash[:notice]).to eq("Documents uploaded successfully.")
          expect(Document.where(files_for: nil).count).to eq(2)
        end
      end
    end
  end

  describe "DELETE /campaigns/:id/documents/:document_id" do
    let(:document) { create(:document, insertion_order: campaign.insertion_order) }

    subject { delete "/campaigns/#{campaign.id}/documents/#{document.id}", params: request_params }

    before do
      sign_in(user)
      subject
    end

    context "without destroy_redirection_path parameter" do
      it "remove the file" do
        expect(response).to redirect_to(campaign_path(campaign.id))
        expect(flash[:notice]).to eq("Document deleted successfully.")
        expect(Document.count).to eq(0)
      end
    end

    context "with destroy_redirection_path parameter" do
      let(:destroy_redirection_path) { documents_request_path(documents_request) }
      let(:request_params) { {destroy_redirection_path: destroy_redirection_path} }

      it "remove the file" do
        expect(response).to redirect_to(destroy_redirection_path)
        expect(flash[:notice]).to eq("Document deleted successfully.")
        expect(Document.count).to eq(0)
      end
    end
  end
end
