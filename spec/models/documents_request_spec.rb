RSpec.describe DocumentsRequest, type: :model do
  before do
    create_list(:campaign_channel, 5)
  end

  describe "associations" do
    subject(:documents_request) { build(:documents_request) }
    it { is_expected.to belong_to(:insertion_order) }
    it { is_expected.to belong_to(:sender).class_name("User") }
    it { is_expected.to have_many(:documents_request_users) }
    it { is_expected.to have_many(:users).through(:documents_request_users) }
  end

  describe "validations" do
    context "when documents_requested is not present" do
      subject { build(:documents_request, documents_requested: nil) }
      it "return requested_options as default" do
        expect(subject.documents_requested).to eq(DocumentsRequest::REQUESTED_OPTIONS)
      end
    end
  end
end
