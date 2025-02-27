RSpec.describe Agency, type: :model do
  describe "soft deletion" do
    it "does not fully destroy agency records" do
      instance = FactoryBot.create(:agency)
      expect { instance.destroy! }.to change { instance.deleted_at }
      expect { Agency.with_deleted.find_by!(id: instance.id) }.to_not raise_error
    end
  end

  describe "associations" do
    context "clients" do
      it { should respond_to(:clients) }
      it { should respond_to(:clients=) }
    end

    context "users" do
      it { should respond_to(:users) }
      it { should respond_to(:users=) }
    end
  end

  describe "validations" do
    let(:instance) { FactoryBot.build(:agency) }

    context "name" do
      it "must be present" do
        instance.name = nil
        expect(instance).to be_invalid

        instance.name = ""
        expect(instance).to be_invalid

        instance.name = Faker::Company.name
        expect(instance).to be_valid
      end

      it "must be unique" do
        name = Faker::Company.name

        instance.name = name
        expect(instance).to be_valid

        FactoryBot.create(:agency, name: name)
        expect(instance).to be_invalid

        instance.name = Faker::Company.name
        expect(instance).to be_valid
      end
    end
  end
end
