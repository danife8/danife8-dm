RSpec.describe User, type: :model do
  subject { FactoryBot.build(:user) }
  let(:user_roles) {
    %i[
      admin_role
      account_manager_role
      campaign_manager_role
      reviewer_role
      employee_role
      agency_admin_role
      agency_user_role
      client_user_role
    ]
  }

  describe "soft deletion" do
    let(:instance) { FactoryBot.create(:user, aasm_state: aasm_state) }
    let(:aasm_state) { "active" }

    it "does not fully destroy user records" do
      expect { instance.destroy! }.to change { instance.deleted_at }
      expect { User.with_deleted.find_by!(id: instance.id) }.to_not raise_error
    end

    context "when user state is pending" do
      let(:aasm_state) { "pending" }

      it "changes to inactive" do
        expect { instance.destroy! }.to change {
          instance.reload.aasm_state
        }.to("inactive")
      end
    end

    context "when user state is active" do
      let(:aasm_state) { "active" }

      it "changes to inactive" do
        expect { instance.destroy! }.to change {
          instance.reload.aasm_state
        }.to("inactive")
      end
    end

    context "when user state is inactive" do
      let(:aasm_state) { "inactive" }

      it "does not change from inactive" do
        expect { instance.destroy! }.to_not change {
          instance.reload.aasm_state
        }.from("inactive")
      end
    end
  end

  describe ".search_by_email" do
    context "when emails start with query" do
      it "returns matching user records" do
        query = "needle"

        matching_users = [
          FactoryBot.create(:user, email: "#{query}1@example.com"),
          FactoryBot.create(:user, email: "#{query}2@example.com"),
          FactoryBot.create(:user, email: "#{query}3@example.com")
        ].sort

        # Create some users without the query.
        3.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_email(query).sort).to eq(matching_users)
      end
    end

    context "when emails end with query" do
      it "returns matching user records" do
        query = "needle.com"

        matching_users = [
          FactoryBot.create(:user, email: "email1@#{query}"),
          FactoryBot.create(:user, email: "email2@#{query}"),
          FactoryBot.create(:user, email: "email3@#{query}")
        ].sort

        # Create some users without the query.
        3.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_email(query).sort).to eq(matching_users)
      end
    end

    context "when emails contain query" do
      it "returns matching user records" do
        query = "needle"

        matching_users = [
          FactoryBot.create(:user, email: "user-#{query}@example.com"),
          FactoryBot.create(:user, email: "user@#{query}.com"),
          FactoryBot.create(:user, email: "hay#{query}stack@example.com")
        ].sort

        # Create some users without the query.
        3.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_email(query).sort).to eq(matching_users)
      end
    end

    context "when email equals query" do
      it "returns matching user record" do
        query = "needle@haystack.com"

        matching_users = [FactoryBot.create(:user, email: query)]

        # Create some users without the query.
        3.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_email(query)).to eq(matching_users)
      end
    end

    context "when no emails match query" do
      it "returns empty results" do
        query = "needle"

        # Create some users without the query.
        6.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_email(query)).to be_empty
      end
    end

    context "when query is not present" do
      it "returns empty results" do
        query = [nil, ""].sample

        # Create some users without the query.
        6.times do
          FactoryBot.create(:user)
        end

        expect(described_class.search_by_email(query)).to be_empty
      end
    end
  end

  describe "associations" do
    context "agency" do
      it { should belong_to(:agency).inverse_of(:users) }
    end

    context "user_role" do
      it { should belong_to(:user_role).inverse_of(:users) }
    end

    context "client" do
      it { should belong_to(:client).optional(true).inverse_of(:users) }
    end

    context "media_plans" do
      it { should have_many(:media_plans).with_foreign_key(:reviewer_id) }
    end

    context "own_media_plans" do
      it { should have_many(:own_media_plans).class_name("MediaPlan").with_foreign_key(:creator_id) }
    end

    context "export_logs" do
      it { should have_many(:export_logs) }
    end

    context "reporting_dashboards" do
      it { should have_and_belong_to_many(:reporting_dashboards).join_table(:reporting_dashboards_users) }
    end

    context "documents_request_users" do
      it { should have_many(:documents_request_users) }
    end

    context "documents_requests" do
      it { should have_many(:documents_requests).through(:documents_request_users) }
    end

    context "campaigns" do
      it { should have_many(:campaigns).through(:documents_requests) }
    end
  end

  describe "devise behavior" do
    it "includes confirmable" do
      expect(subject.devise_modules).to include(:confirmable)
    end

    it "includes database_authenticatable" do
      expect(subject.devise_modules).to include(:database_authenticatable)
    end

    it "includes invitable" do
      expect(subject.devise_modules).to include(:invitable)
    end

    it "includes lockable" do
      expect(subject.devise_modules).to include(:lockable)
    end

    it "includes recoverable" do
      expect(subject.devise_modules).to include(:recoverable)
    end

    it "includes registerable" do
      expect(subject.devise_modules).to include(:registerable)
    end

    it "includes rememberable" do
      expect(subject.devise_modules).to include(:rememberable)
    end

    it "includes timeoutable" do
      expect(subject.devise_modules).to include(:timeoutable)
    end

    it "includes trackable" do
      expect(subject.devise_modules).to include(:trackable)
    end

    it "includes validatable" do
      expect(subject.devise_modules).to include(:validatable)
    end
  end

  describe "validations" do
    let(:instance) { FactoryBot.build(:user) }

    context "user_role_id" do
      it "must be present" do
        instance.user_role = nil
        expect(instance).to be_invalid

        instance.user_role = FactoryBot.create(:user_role)
        expect(instance).to be_valid
      end
    end

    context "email" do
      it "must be present" do
        instance.email = ""
        expect(instance).to be_invalid

        instance.email = nil
        expect(instance).to be_invalid

        instance.email = Faker::Internet.email
        expect(instance).to be_valid
      end

      it "must be unique" do
        email = Faker::Internet.email

        instance.email = email
        expect(instance).to be_valid

        FactoryBot.create(:user, email: email)
        expect(instance).to be_invalid

        instance.email = Faker::Internet.email
        expect(instance).to be_valid
      end
    end

    context "password" do
      it "must be present" do
        instance.password = ""
        expect(instance).to be_invalid

        instance.password = nil
        expect(instance).to be_invalid

        instance.password = Faker::Internet.password
        expect(instance).to be_valid
      end

      it "must be >= 8 characters" do
        instance.password = "abcd123"
        expect(instance).to be_invalid

        instance.password = "abcd1234"
        expect(instance).to be_valid
      end
    end

    context "aasm_state" do
    end

    context "first_name" do
      it "must be present" do
        instance.first_name = nil
        expect(instance).to be_invalid

        instance.first_name = ""
        expect(instance).to be_invalid

        instance.first_name = Faker::Name.first_name
        expect(instance).to be_valid
      end
    end

    context "last_name" do
      it "must be present" do
        instance.last_name = nil
        expect(instance).to be_invalid

        instance.last_name = ""
        expect(instance).to be_invalid

        instance.last_name = Faker::Name.last_name
        expect(instance).to be_valid
      end
    end

    context "phone_number" do
      it "must be present" do
        instance.phone_number = nil
        expect(instance).to be_invalid

        instance.phone_number = ""
        expect(instance).to be_invalid

        instance.phone_number = "6155551212"
        expect(instance).to be_valid
      end

      it "must be numeric" do
        instance.phone_number = "ABCDEFGHIJ"
        expect(instance).to be_invalid

        instance.phone_number = "866NOBLSHT"
        expect(instance).to be_invalid

        instance.phone_number = "6155557890"
        expect(instance).to be_valid
      end

      it "must have length of 10" do
        instance.phone_number = "123456789"
        expect(instance).to be_invalid

        instance.phone_number = "12345678901"
        expect(instance).to be_invalid

        instance.phone_number = "1234567890"
        expect(instance).to be_valid
      end
    end

    context "super_admin" do
      it "must be boolean value" do
        [nil, ""].each do |value|
          instance.super_admin = value
          expect(instance).to be_invalid
        end

        [true, false].each do |boolean|
          instance.super_admin = boolean
          expect(instance).to be_valid
        end
      end
    end

    context "client_id" do
      it "must be optional" do
        instance.client = nil
        expect(instance).to be_valid

        instance.client = create(:client)
        expect(instance).to be_valid
      end
    end
  end

  describe "before create" do
    let(:instance) { FactoryBot.build(:user) }

    context "first_name" do
      it "removes whitespace" do
        first_name = " #{Faker::Name.first_name} "
        instance.first_name = first_name

        expect {
          instance.save!
        }.to change {
          instance.first_name
        }.to(first_name.strip)
      end
    end

    context "last_name" do
      it "removes whitespace" do
        last_name = " #{Faker::Name.last_name} "
        instance.last_name = last_name

        expect {
          instance.save!
        }.to change {
          instance.last_name
        }.to(last_name.strip)
      end
    end

    context "phone_number" do
      it "removes whitespace" do
        phone_number = " 1234567890 "
        instance.phone_number = phone_number

        expect {
          instance.save!
        }.to change {
          instance.phone_number
        }.to(phone_number.strip)
      end

      it "removes formatting characters" do
        phone_number = [
          "123-456-7890",
          "(123) 456-7890",
          "123.456.7890",
          "123 456 7890",
          "+1234567890"
        ].sample
        instance.phone_number = phone_number

        expect {
          instance.save!
        }.to change {
          instance.phone_number
        }.to("1234567890")
      end
    end
  end

  describe "before update" do
    let(:instance) { FactoryBot.create(:user) }

    context "first_name" do
      it "removes whitespace" do
        first_name = " #{Faker::Name.first_name} "
        instance.first_name = first_name

        expect {
          instance.save!
        }.to change {
          instance.first_name
        }.to(first_name.strip)
      end
    end

    context "last_name" do
      it "removes whitespace" do
        last_name = " #{Faker::Name.last_name} "
        instance.last_name = last_name

        expect {
          instance.save!
        }.to change {
          instance.last_name
        }.to(last_name.strip)
      end
    end

    context "phone_number" do
      it "removes whitespace" do
        phone_number = " 1234567890 "
        instance.phone_number = phone_number

        expect {
          instance.save!
        }.to change {
          instance.phone_number
        }.to(phone_number.strip)
      end

      it "removes formatting characters" do
        phone_number = [
          "123-456-7890",
          "(123) 456-7890",
          "123.456.7890",
          "123 456 7890",
          "+1234567890"
        ].sample
        instance.phone_number = phone_number

        expect {
          instance.save!
        }.to change {
          instance.phone_number
        }.to("1234567890")
      end
    end
  end

  describe "state machine behavior" do
    let(:instance) { FactoryBot.build(:user) }
    it_behaves_like "includes a aasm_state field"

    it "defaults to pending state" do
      instance = User.new
      expect(instance).to have_state(:pending)
    end

    context "when pending state" do
      let(:instance) { User.new(aasm_state: "pending") }

      it "can be enabled" do
        expect(instance).to allow_event(:enable)
        expect(instance).to transition_from(:pending).to(:active).on_event(:enable)
      end

      it "can be disabled" do
        expect(instance).to allow_event(:disable)
        expect(instance).to transition_from(:pending).to(:inactive).on_event(:disable)
      end
    end

    context "when active state" do
      let(:instance) { User.new(aasm_state: "active") }

      it "can not be enabled" do
        expect(instance).to_not allow_event(:enable)
        expect(instance).to_not allow_transition_to(:active)
      end

      it "can be disabled" do
        expect(instance).to allow_event(:disable)
        expect(instance).to transition_from(:active).to(:inactive).on_event(:disable)
      end
    end

    context "when inactive state" do
      let(:instance) { User.new(aasm_state: "inactive") }

      it "can be enabled" do
        expect(instance).to allow_event(:enable)
        expect(instance).to transition_from(:inactive).to(:active).on_event(:enable)
      end

      it "can not be disabled" do
        expect(instance).to_not allow_event(:disable)
        expect(instance).to_not allow_transition_to(:inactive)
      end
    end
  end

  describe "#agency_name" do
    it "returns agency name" do
      expect(subject.agency_name).to eq(subject.agency.name)
    end
  end

  describe "#user_role_label" do
    it "returns user_role label" do
      expect(subject.user_role_label).to eq(subject.user_role.label)
    end
  end

  describe "#user_role_name" do
    it "returns user_role name" do
      expect(subject.user_role_name).to eq(subject.user_role.name)
    end
  end

  describe "#agency_clients" do
    it "returns clients associated with the agency" do
      expect(subject.agency_clients).to eq(subject.agency.clients)
    end
  end

  describe "#client_name" do
    let!(:user_role) { create(:client_user_role) }
    let!(:client) { create(:client) }

    context "when user has client" do
      before do
        subject.update!(client:, user_role:)
      end

      it "returns client_name" do
        expect(subject.client_name).to eq(client.name)
      end
    end

    context "when user has no client" do
      it "returns nil" do
        expect(subject.client_name).to eq(nil)
      end
    end
  end

  describe "#admin?" do
    context "when user role is admin" do
      before do
        subject.user_role = build(:admin_role)
      end

      it "returns true" do
        expect(subject.admin?).to eq(true)
      end
    end

    context "when user role is not admin" do
      before do
        user_role = user_roles.excluding(:admin_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.admin?).to eq(false)
      end
    end
  end

  describe "#account_manager?" do
    context "when user role is account manager" do
      before do
        subject.user_role = build(:account_manager_role)
      end

      it "returns true" do
        expect(subject.account_manager?).to eq(true)
      end
    end

    context "when user role is not account manager" do
      before do
        user_role = user_roles.excluding(:account_manager_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.account_manager?).to eq(false)
      end
    end
  end

  describe "#campaign_manager?" do
    context "when user role is campaign manager" do
      before do
        subject.user_role = build(:campaign_manager_role)
      end

      it "returns true" do
        expect(subject.campaign_manager?).to eq(true)
      end
    end

    context "when user role is not campaign manager" do
      before do
        user_role = user_roles.excluding(:campaign_manager_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.campaign_manager?).to eq(false)
      end
    end
  end

  describe "#reviewer?" do
    context "when user role is reviewer" do
      before do
        subject.user_role = build(:reviewer_role)
      end

      it "returns true" do
        expect(subject.reviewer?).to eq(true)
      end
    end

    context "when user role is not reviewer" do
      before do
        user_role = user_roles.excluding(:reviewer_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.reviewer?).to eq(false)
      end
    end
  end

  describe "#employee?" do
    context "when user role is employee" do
      before do
        subject.user_role = build(:employee_role)
      end

      it "returns true" do
        expect(subject.employee?).to eq(true)
      end
    end

    context "when user role is not employee" do
      before do
        user_role = user_roles.excluding(:employee_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.employee?).to eq(false)
      end
    end
  end

  describe "#agency_admin?" do
    context "when user role is agency_admin" do
      before do
        subject.user_role = build(:agency_admin_role)
      end

      it "returns true" do
        expect(subject.agency_admin?).to eq(true)
      end
    end

    context "when user role is not agency_admin" do
      before do
        user_role = user_roles.excluding(:agency_admin_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.agency_admin?).to eq(false)
      end
    end
  end

  describe "#agency_user?" do
    context "when user role is agency_user" do
      before do
        subject.user_role = build(:agency_user_role)
      end

      it "returns true" do
        expect(subject.agency_user?).to eq(true)
      end
    end

    context "when user role is not agency_user" do
      before do
        user_role = user_roles.excluding(:agency_user_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.agency_user?).to eq(false)
      end
    end
  end

  describe "#client_user?" do
    context "when user role is client_user" do
      before do
        subject.user_role = build(:client_user_role)
      end

      it "returns true" do
        expect(subject.client_user?).to eq(true)
      end
    end

    context "when user role is not client_user" do
      before do
        user_role = user_roles.excluding(:client_user_role).sample
        subject.user_role = build(user_role)
      end

      it "returns false" do
        expect(subject.client_user?).to eq(false)
      end
    end
  end

  describe "#full_name" do
    it "returns string with first and last name" do
      expected_result = subject.first_name + " " + subject.last_name
      expect(subject.full_name).to eq(expected_result)
    end
  end

  describe "#send_devise_notification" do
    let!(:instance) { FactoryBot.create(:user, confirmed_at: nil).reload }

    it "sends email notification async" do
      expect {
        instance.resend_confirmation_instructions
      }.to change {
        Sidekiq::Worker.jobs.size
      }.by(1)
    end
  end

  describe "before_save callback: #clear_client_if_not_client_user_role" do
    let!(:client) { create(:client) }
    let(:user) { create(:user, user_role:, client:) }

    context "when the user role is client_user" do
      let(:user_role) { create(:client_user_role) }

      it "does not clear the client association" do
        user.update!(first_name: "First Name")
        expect(user.client).to eq(client)
      end
    end

    context "when the user role is not client_user" do
      let(:user_role) { create(:admin_role) }

      it "clears the client association" do
        user.update!(first_name: "First Name")
        expect(user.client).to be_nil
      end
    end

    context "when the user role is changed from client_user to admin" do
      let(:user_role) { create(:client_user_role) }

      it "clears the client association" do
        user.update!(user_role: build(:admin_role))
        expect(user.client).to be_nil
      end
    end

    context "when the user role is changed from admin to client_user" do
      let(:user_role) { create(:admin_role) }
      let(:client) { create(:client) }

      it "does not clear the client association if a client is set after role change" do
        user.update!(user_role: build(:client_user_role), client:)
        expect(user.client).to eq(client)
      end
    end
  end
end
