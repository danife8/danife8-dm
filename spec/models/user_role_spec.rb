RSpec.describe UserRole, type: :model do
  describe "associations" do
    context "users" do
      it { should respond_to(:users) }
      it { should respond_to(:users=) }
    end
  end

  describe "validations" do
    let(:instance) { FactoryBot.build(:user_role) }

    context "name" do
      it "must be present" do
        instance.name = nil
        expect(instance).to be_invalid

        instance.name = ""
        expect(instance).to be_invalid

        instance.name = "user_role"
        expect(instance).to be_valid
      end

      it "must be unique" do
        name = "user_role"

        instance.name = name
        expect(instance).to be_valid

        FactoryBot.create(:user_role, name: name)
        expect(instance).to be_invalid

        instance.name = "other_user_role"
        expect(instance).to be_valid
      end
    end

    context "label" do
      it "must be present" do
        instance.label = nil
        expect(instance).to be_invalid

        instance.label = ""
        expect(instance).to be_invalid

        instance.label = "User Role"
        expect(instance).to be_valid
      end
    end
  end

  describe ".client_user" do
    let!(:admin_role) { create(:admin_role) }

    context "when a client user role exists" do
      let!(:client_user_role) { create(:client_user_role) }

      it "returns the client_user role" do
        expect(UserRole.client_user).to eq(client_user_role)
      end
    end

    context "when a client user role does not exist" do
      it "returns nil" do
        expect(UserRole.client_user).to eq(nil)
      end
    end
  end
end
