RSpec.describe "Users", type: :request do
  describe "GET /users" do
    let(:request_params) { {} }

    subject { get "/users", params: request_params }

    context "when no user is logged in" do
      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      it "responds with success" do
        FactoryBot.create_list(:user, 3)
        subject
        expect(response).to have_http_status(:ok)
      end

      it "does not show users from other agencies" do
        other_agency = FactoryBot.create(:agency)

        user1 = FactoryBot.create(:user, agency: admin.agency)
        user2 = FactoryBot.create(:user, agency: other_agency)

        subject
        expect(response.body).to include(user1.email)
        expect(response.body).to_not include(user2.email)
      end

      context "when searching by email" do
        let(:query) { "needle" }

        before do
          request_params[:filter] = {
            q: query
          }
        end

        it "shows users matching search query" do
          matching_users = [
            FactoryBot.create(:user, agency: admin.agency, email: "user-#{query}@example.com"),
            FactoryBot.create(:user, agency: admin.agency, email: "user@#{query}.com"),
            FactoryBot.create(:user, agency: admin.agency, email: "hay#{query}stack@example.com")
          ]

          unmatched_users = [
            FactoryBot.create(:user, agency: admin.agency),
            FactoryBot.create(:user, agency: admin.agency),
            FactoryBot.create(:user, agency: admin.agency)
          ]

          subject
          matching_users.each do |matched_user|
            expect(response.body).to include(matched_user.email)
          end
          unmatched_users.each do |unmatched_user|
            expect(response.body).to_not include(unmatched_user.email)
          end
        end

        context "when filtering by user state" do
          let(:filter_aasm_state) { User.valid_aasm_states.sample }

          before do
            request_params[:filter] = {
              aasm_state: filter_aasm_state
            }
          end

          it "shows users matching search query and selected user state" do
            matching_users = [
              FactoryBot.create(
                :user,
                agency: admin.agency,
                aasm_state: filter_aasm_state,
                email: "user-#{query}@example.com"
              ),
              FactoryBot.create(
                :user,
                agency: admin.agency,
                aasm_state: filter_aasm_state,
                email: "user@#{query}.com"
              ),
              FactoryBot.create(
                :user,
                agency: admin.agency,
                aasm_state: filter_aasm_state,
                email: "hay#{query}stack@example.com"
              )
            ]

            other_aasm_state = User.valid_aasm_states.reject { |s| s == filter_aasm_state }.sample
            unmatched_users = [
              FactoryBot.create(
                :user,
                agency: admin.agency,
                aasm_state: other_aasm_state,
                email: "user-#{query}1@example.com"
              ),
              FactoryBot.create(
                :user,
                agency: admin.agency,
                aasm_state: other_aasm_state,
                email: "user1@#{query}.com"
              ),
              FactoryBot.create(
                :user,
                agency: admin.agency,
                aasm_state: other_aasm_state,
                email: "hay#{query}stack1@example.com"
              )
            ]

            subject
            matching_users.each do |matched_user|
              expect(response.body).to include(matched_user.email)
            end
            unmatched_users.each do |unmatched_user|
              expect(response.body).to_not include(unmatched_user.email)
            end
          end
        end

        it "does not show users from other agencies" do
          other_agency = FactoryBot.create(:agency)

          user1 = FactoryBot.create(:user, agency: admin.agency, email: "#{query}1@example.com")
          user2 = FactoryBot.create(:user, agency: other_agency, email: "#{query}2@example.com")

          subject
          expect(response.body).to include(user1.email)
          expect(response.body).to_not include(user2.email)
        end
      end

      context "when filtering by user state" do
        let(:filter_aasm_state) { User.valid_aasm_states.sample }

        before do
          request_params[:filter] = {
            aasm_state: filter_aasm_state
          }
        end

        it "shows users matching selected user state" do
          matching_users = [
            FactoryBot.create(:user, agency: admin.agency, aasm_state: filter_aasm_state),
            FactoryBot.create(:user, agency: admin.agency, aasm_state: filter_aasm_state),
            FactoryBot.create(:user, agency: admin.agency, aasm_state: filter_aasm_state)
          ]

          other_aasm_state = User.valid_aasm_states.reject { |s| s == filter_aasm_state }.sample
          unmatched_users = [
            FactoryBot.create(:user, agency: admin.agency, aasm_state: other_aasm_state),
            FactoryBot.create(:user, agency: admin.agency, aasm_state: other_aasm_state),
            FactoryBot.create(:user, agency: admin.agency, aasm_state: other_aasm_state)
          ]

          subject
          matching_users.each do |matched_user|
            expect(response.body).to include(matched_user.email)
          end
          unmatched_users.each do |unmatched_user|
            expect(response.body).to_not include(unmatched_user.email)
          end
        end

        it "does not show users from other agencies" do
          other_agency = FactoryBot.create(:agency)

          user1 = FactoryBot.create(:user, agency: admin.agency, aasm_state: filter_aasm_state)
          user2 = FactoryBot.create(:user, agency: other_agency, aasm_state: filter_aasm_state)

          subject
          expect(response.body).to include(user1.email)
          expect(response.body).to_not include(user2.email)
        end
      end
    end

    context "when user is a super admin" do
      let(:super_admin) {
        FactoryBot.create(
          :user,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(super_admin)
      end

      it "responds with success" do
        FactoryBot.create_list(:user, 3)
        subject
        expect(response).to have_http_status(:ok)
      end

      it "shows users from other agencies" do
        other_agency = FactoryBot.create(:agency)

        user1 = FactoryBot.create(:user, agency: super_admin.agency)
        user2 = FactoryBot.create(:user, agency: other_agency)

        subject
        expect(response.body).to include(user1.email)
        expect(response.body).to include(user2.email)
      end

      context "when searching by email" do
        let(:query) { "needle" }

        before do
          request_params[:filter] = {
            q: query
          }
        end

        it "shows users matching search query" do
          matching_users = [
            FactoryBot.create(:user, agency: super_admin.agency, email: "user-#{query}@example.com"),
            FactoryBot.create(:user, agency: super_admin.agency, email: "user@#{query}.com"),
            FactoryBot.create(:user, agency: super_admin.agency, email: "hay#{query}stack@example.com")
          ]

          unmatched_users = [
            FactoryBot.create(:user, agency: super_admin.agency),
            FactoryBot.create(:user, agency: super_admin.agency),
            FactoryBot.create(:user, agency: super_admin.agency)
          ]

          subject
          matching_users.each do |matched_user|
            expect(response.body).to include(matched_user.email)
          end
          unmatched_users.each do |unmatched_user|
            expect(response.body).to_not include(unmatched_user.email)
          end
        end

        context "when filtering by user state" do
          let(:filter_aasm_state) { User.valid_aasm_states.sample }

          before do
            request_params[:filter] = {
              aasm_state: filter_aasm_state
            }
          end

          it "shows users matching search query and selected user state" do
            matching_users = [
              FactoryBot.create(
                :user,
                agency: super_admin.agency,
                aasm_state: filter_aasm_state,
                email: "user-#{query}@example.com"
              ),
              FactoryBot.create(
                :user,
                agency: super_admin.agency,
                aasm_state: filter_aasm_state,
                email: "user@#{query}.com"
              ),
              FactoryBot.create(
                :user,
                agency: super_admin.agency,
                aasm_state: filter_aasm_state,
                email: "hay#{query}stack@example.com"
              )
            ]

            other_aasm_state = User.valid_aasm_states.reject { |s| s == filter_aasm_state }.sample
            unmatched_users = [
              FactoryBot.create(
                :user,
                agency: super_admin.agency,
                aasm_state: other_aasm_state,
                email: "user-#{query}1@example.com"
              ),
              FactoryBot.create(
                :user,
                agency: super_admin.agency,
                aasm_state: other_aasm_state,
                email: "user1@#{query}.com"
              ),
              FactoryBot.create(
                :user,
                agency: super_admin.agency,
                aasm_state: other_aasm_state,
                email: "hay#{query}stack1@example.com"
              )
            ]

            subject
            matching_users.each do |matched_user|
              expect(response.body).to include(matched_user.email)
            end
            unmatched_users.each do |unmatched_user|
              expect(response.body).to_not include(unmatched_user.email)
            end
          end
        end

        it "shows users from other agencies" do
          other_agency = FactoryBot.create(:agency)

          user1 = FactoryBot.create(:user, agency: super_admin.agency, email: "#{query}1@example.com")
          user2 = FactoryBot.create(:user, agency: other_agency, email: "#{query}2@example.com")

          subject
          expect(response.body).to include(user1.email)
          expect(response.body).to include(user2.email)
        end
      end

      context "when filtering by user state" do
        let(:filter_aasm_state) { User.valid_aasm_states.sample }

        before do
          request_params[:filter] = {
            aasm_state: filter_aasm_state
          }
        end

        it "shows users matching selected user state" do
          matching_users = [
            FactoryBot.create(:user, agency: super_admin.agency, aasm_state: filter_aasm_state),
            FactoryBot.create(:user, agency: super_admin.agency, aasm_state: filter_aasm_state),
            FactoryBot.create(:user, agency: super_admin.agency, aasm_state: filter_aasm_state)
          ]

          other_aasm_state = User.valid_aasm_states.reject { |s| s == filter_aasm_state }.sample
          unmatched_users = [
            FactoryBot.create(:user, agency: super_admin.agency, aasm_state: other_aasm_state),
            FactoryBot.create(:user, agency: super_admin.agency, aasm_state: other_aasm_state),
            FactoryBot.create(:user, agency: super_admin.agency, aasm_state: other_aasm_state)
          ]

          subject
          matching_users.each do |matched_user|
            expect(response.body).to include(matched_user.email)
          end
          unmatched_users.each do |unmatched_user|
            expect(response.body).to_not include(unmatched_user.email)
          end
        end

        it "shows users from other agencies" do
          other_agency = FactoryBot.create(:agency)

          user1 = FactoryBot.create(:user, agency: super_admin.agency, aasm_state: filter_aasm_state)
          user2 = FactoryBot.create(:user, agency: other_agency, aasm_state: filter_aasm_state)

          subject
          expect(response.body).to include(user1.email)
          expect(response.body).to include(user2.email)
        end
      end
    end
  end

  describe "GET /users/:id" do
    let(:user) { FactoryBot.create(:user, agency: agency) }
    let(:agency) { FactoryBot.create(:agency) }

    subject { get "/users/#{user.to_param}" }

    context "when no user is logged in" do
      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      it "responds with success" do
        subject
        expect(response).to have_http_status(:ok)
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "responds with not found" do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when user is a super admin" do
      let(:super_admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(super_admin)
      end

      it "responds with success" do
        subject
        expect(response).to have_http_status(:ok)
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "responds with success" do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "GET /users/new" do
    subject { get "/users/new" }

    context "when no user is logged in" do
      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      it "responds with success" do
        subject
        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is a super admin" do
      let(:admin) {
        create(
          :user,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      it "responds with success" do
        subject
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /users/:id/edit" do
    let(:user) { FactoryBot.create(:user, agency: agency) }
    let(:agency) { FactoryBot.create(:agency) }

    subject { get "/users/#{user.to_param}/edit" }

    context "when no user is logged in" do
      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      it "responds with success" do
        subject
        expect(response).to have_http_status(:ok)
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "responds with not found" do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when user is a super admin" do
      let(:super_admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(super_admin)
      end

      it "responds with success" do
        subject
        expect(response).to have_http_status(:ok)
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "responds with success" do
          subject
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "POST /users" do
    let(:request_params) {
      {
        user: user_params
      }
    }
    let(:user_params) {
      {
        email: Faker::Internet.email,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        phone_number: rand(1000000000..9999999999).to_s,
        user_role_id: user_role.id
      }
    }
    let(:user_role) { FactoryBot.create(:user_role) }

    subject {
      post "/users", params: request_params
    }

    context "when no user is logged in" do
      it "does not create a new User" do
        expect { subject }.to_not change(User, :count)
      end

      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not create a new User" do
        expect { subject }.to_not change(User, :count)
      end
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not create a new User" do
        expect { subject }.to_not change(User, :count)
      end
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not create a new User" do
        expect { subject }.to_not change(User, :count)
      end
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      context "with valid parameters" do
        it "creates a new User" do
          expect { subject }.to change(User, :count).by(1)
        end

        it "assigns request param values" do
          subject

          user = User.last
          expect(user.agency).to eq(admin.agency)
          expect(user.email).to eq(user_params[:email])
          expect(user.first_name).to eq(user_params[:first_name])
          expect(user.last_name).to eq(user_params[:last_name])
          expect(user.phone_number).to eq(user_params[:phone_number])
          expect(user.user_role).to eq(user_role)
          expect(user.pending?).to eq(true)
        end

        it "does not assign user state param" do
          aasm_state = User.valid_aasm_states.reject { |s| s == "pending" }.sample
          user_params[:aasm_state] = aasm_state

          subject

          user = User.last
          expect(user.pending?).to eq(true)
        end

        it "does not assign agency param" do
          agency = FactoryBot.create(:agency)
          user_params[:agency_id] = agency.id

          subject

          user = User.last
          expect(user.agency).to_not eq(agency)
        end

        it "skips confirmation" do
          subject

          user = User.last
          expect(user.confirmed?).to eq(true)
        end

        it "sends invitation" do
          expect(Devise::Mailer).to receive(:invitation_instructions)
            .with(
              an_instance_of(User),
              an_instance_of(String),
              {}
            )
            .and_return(double("mailer", deliver_later: true))
          subject

          user = User.last
          expect(user.invited_to_sign_up?).to eq(true)
        end

        it "redirects to the created user" do
          subject
          user = User.last
          expect(response).to redirect_to("/users/#{user.to_param}")
        end
      end

      context "with invalid parameters" do
        let(:user_params) {
          {
            email: ["", "email address"].sample,
            first_name: ["", Faker::Name.first_name].sample,
            last_name: "",
            phone_number: ["", "phone number"].sample,
            user_role_id: [nil, ""].sample
          }
        }

        it "does not create a new User" do
          expect { subject }.to_not change(User, :count)
        end

        it "responds with unprocessable entity" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with invalid role" do
        let(:reviewer_role) { create(:reviewer_role) }
        let(:user_params) {
          {
            email: ["", "email address"].sample,
            first_name: ["", Faker::Name.first_name].sample,
            last_name: "",
            phone_number: ["", "phone number"].sample,
            user_role_id: reviewer_role.id
          }
        }

        it_behaves_like "unauthorized resource policy request"
      end
    end

    context "when user is a super admin" do
      let(:super_admin) {
        FactoryBot.create(
          :user,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(super_admin)
      end

      context "with valid parameters" do
        before do
          user_params[:agency_id] = super_admin.agency_id
          user_params[:super_admin] = true
        end

        it "creates a new User" do
          expect { subject }.to change(User, :count).by(1)
        end

        it "assigns request param values" do
          subject

          user = User.last
          expect(user.agency).to eq(super_admin.agency)
          expect(user.email).to eq(user_params[:email])
          expect(user.first_name).to eq(user_params[:first_name])
          expect(user.last_name).to eq(user_params[:last_name])
          expect(user.phone_number).to eq(user_params[:phone_number])
          expect(user.user_role).to eq(user_role)
          expect(user.pending?).to eq(true)
          expect(user.super_admin).to eq(true)
        end

        it "does not assign user state param" do
          aasm_state = User.valid_aasm_states.reject { |s| s == "pending" }.sample
          user_params[:aasm_state] = aasm_state

          subject

          user = User.last
          expect(user.pending?).to eq(true)
        end

        it "assigns agency param" do
          agency = FactoryBot.create(:agency)
          user_params[:agency_id] = agency.id

          subject

          user = User.last
          expect(user.agency).to eq(agency)
        end

        it "skips confirmation" do
          subject

          user = User.last
          expect(user.confirmed?).to eq(true)
        end

        it "sends invitation" do
          expect(Devise::Mailer).to receive(:invitation_instructions)
            .with(
              an_instance_of(User),
              an_instance_of(String),
              {}
            )
            .and_return(double("mailer", deliver_later: true))
          subject

          user = User.last
          expect(user.invited_to_sign_up?).to eq(true)
        end

        it "redirects to the created user" do
          subject
          user = User.last
          expect(response).to redirect_to("/users/#{user.to_param}")
        end
      end

      context "with invalid parameters" do
        let(:user_params) {
          {
            email: ["", "email address"].sample,
            first_name: ["", Faker::Name.first_name].sample,
            last_name: "",
            phone_number: ["", "phone number"].sample,
            user_role_id: [nil, ""].sample,
            agency_id: [nil, ""].sample
          }
        }

        it "does not create a new User" do
          expect { subject }.to_not change(User, :count)
        end

        it "responds with unprocessable entity" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe "PATCH /users/:id" do
    let(:user) { FactoryBot.create(:user, agency: agency) }
    let(:agency) { FactoryBot.create(:agency) }
    let(:request_params) {
      {
        user: user_params
      }
    }
    let(:user_params) {
      {
        email: Faker::Internet.email,
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        phone_number: rand(1000000000..9999999999).to_s,
        user_role_id: updated_user_role.id,
        aasm_state: User.valid_aasm_states.sample
      }
    }
    let(:updated_user_role) { FactoryBot.create(:user_role) }

    subject {
      patch "/users/#{user.to_param}", params: request_params
    }

    context "when no user is logged in" do
      it "does not change the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end

      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not change the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not change the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not change the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      context "with valid parameters" do
        it "updates the requested user" do
          expect { subject }.to change { user.reload.as_json }
        end

        it "assigns request param values" do
          subject

          user.reload
          expect(user.unconfirmed_email).to eq(user_params[:email])
          expect(user.first_name).to eq(user_params[:first_name])
          expect(user.last_name).to eq(user_params[:last_name])
          expect(user.phone_number).to eq(user_params[:phone_number])
          expect(user.user_role).to eq(updated_user_role)
          expect(user.aasm_state).to eq(user_params[:aasm_state])
        end

        it "does not assign agency param" do
          agency = FactoryBot.create(:agency)
          user_params[:agency_id] = agency.id

          subject

          user.reload
          expect(user.agency).to_not eq(agency)
        end

        it "redirects to the user" do
          subject
          expect(response).to redirect_to("/users/#{user.to_param}")
        end
      end

      context "with invalid parameters" do
        let(:user_params) {
          {
            email: ["", "email address"].sample,
            first_name: ["", Faker::Name.first_name].sample,
            last_name: "",
            phone_number: ["", "phone number"].sample,
            user_role_id: [nil, ""].sample,
            aasm_state: ["", "unsupported"].sample
          }
        }

        it "does not change the user" do
          expect { subject }.to_not change { user.reload.as_json }
        end

        it "responds with unprocessable entity" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with invalid role" do
        let(:reviewer_role) { create(:reviewer_role) }
        let(:user_params) {
          {
            email: ["", "email address"].sample,
            first_name: ["", Faker::Name.first_name].sample,
            last_name: "",
            phone_number: ["", "phone number"].sample,
            user_role_id: reviewer_role.id,
            aasm_state: ["", "unsupported"].sample
          }
        }

        it_behaves_like "unauthorized resource policy request"
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "does not change the user" do
          expect {
            begin
              subject
            rescue
            end
          }.to_not change { user.reload.as_json }
        end

        it "responds with not found" do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when user is a super admin" do
      let(:super_admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(super_admin)
      end

      context "with valid parameters" do
        before do
          user_params[:agency_id] = user.agency_id
          user_params[:super_admin] = user.super_admin
        end

        it "updates the requested user" do
          expect { subject }.to change { user.reload.as_json }
        end

        it "assigns request param values" do
          subject

          user.reload
          expect(user.unconfirmed_email).to eq(user_params[:email])
          expect(user.first_name).to eq(user_params[:first_name])
          expect(user.last_name).to eq(user_params[:last_name])
          expect(user.phone_number).to eq(user_params[:phone_number])
          expect(user.user_role).to eq(updated_user_role)
          expect(user.aasm_state).to eq(user_params[:aasm_state])
          expect(user.super_admin).to eq(user_params[:super_admin])
        end

        it "assigns agency param" do
          agency = FactoryBot.create(:agency)
          user_params[:agency_id] = agency.id

          subject

          user.reload
          expect(user.agency).to eq(agency)
        end

        it "redirects to the user" do
          subject
          expect(response).to redirect_to("/users/#{user.to_param}")
        end
      end

      context "with invalid parameters" do
        let(:user_params) {
          {
            email: ["", "email address"].sample,
            first_name: ["", Faker::Name.first_name].sample,
            last_name: "",
            phone_number: ["", "phone number"].sample,
            user_role_id: [nil, ""].sample,
            aasm_state: ["", "unsupported"].sample,
            agency_id: [nil, ""].sample
          }
        }

        it "does not change the user" do
          expect { subject }.to_not change { user.reload.as_json }
        end

        it "responds with unprocessable entity" do
          subject
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
          user_params[:agency_id] = other_agency.id
        end

        it "updates the requested user" do
          expect { subject }.to change { user.reload.as_json }
        end

        it "assigns request param values" do
          subject

          user.reload
          expect(user.unconfirmed_email).to eq(user_params[:email])
          expect(user.first_name).to eq(user_params[:first_name])
          expect(user.last_name).to eq(user_params[:last_name])
          expect(user.phone_number).to eq(user_params[:phone_number])
          expect(user.user_role).to eq(updated_user_role)
          expect(user.aasm_state).to eq(user_params[:aasm_state])
        end

        it "assigns agency param" do
          updated_agency = FactoryBot.create(:agency)
          user_params[:agency_id] = updated_agency.id

          subject

          user.reload
          expect(user.agency).to eq(updated_agency)
        end

        it "redirects to the user" do
          subject
          expect(response).to redirect_to("/users/#{user.to_param}")
        end
      end
    end
  end

  describe "DELETE /users/:id" do
    let(:user) { FactoryBot.create(:user, agency: agency) }
    let(:agency) { FactoryBot.create(:agency) }

    subject { delete "/users/#{user.to_param}" }

    context "when no user is logged in" do
      it "does not destroy the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end

      it "responds with redirect to login" do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is a reviewer" do
      let(:reviewer) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: reviewer_role,
          aasm_state: aasm_state
        )
      }
      let(:reviewer_role) {
        FactoryBot.create(:reviewer_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(reviewer)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not destroy the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end
    end

    context "when user is a campaign manager" do
      let(:campaign_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: campaign_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:campaign_manager_role) {
        FactoryBot.create(:campaign_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(campaign_manager)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not destroy the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end
    end

    context "when user is an account manager" do
      let(:account_manager) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: account_manager_role,
          aasm_state: aasm_state
        )
      }
      let(:account_manager_role) {
        FactoryBot.create(:account_manager_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(account_manager)
      end

      it_behaves_like "unauthorized resource policy request"

      it "does not destroy the user" do
        expect { subject }.to_not change { user.reload.as_json }
      end
    end

    context "when user is an admin" do
      let(:admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(admin)
      end

      it "destroys the requested user" do
        expect { subject }.to change(User.only_deleted, :count).by(1)
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to the users list" do
        subject
        expect(response).to redirect_to("/users")
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "does not destroy the user" do
          expect {
            begin
              subject
            rescue
            end
          }.to_not change { user.reload.as_json }
        end

        it "responds with not found" do
          subject
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when user is a super admin" do
      let(:super_admin) {
        FactoryBot.create(
          :user,
          agency: agency,
          user_role: admin_role,
          aasm_state: aasm_state,
          super_admin: true
        )
      }
      let(:admin_role) {
        FactoryBot.create(:admin_role)
      }
      let(:aasm_state) { "active" }

      before do
        sign_in(super_admin)
      end

      it "destroys the requested user" do
        expect { subject }.to change(User.only_deleted, :count).by(1)
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "redirects to the users list" do
        subject
        expect(response).to redirect_to("/users")
      end

      context "when user belongs to another agency" do
        before do
          other_agency = FactoryBot.create(:agency)
          user.update!(agency: other_agency)
        end

        it "destroys the requested user" do
          expect { subject }.to change(User.only_deleted, :count).by(1)
          expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "redirects to the users list" do
          subject
          expect(response).to redirect_to("/users")
        end
      end
    end
  end
end
