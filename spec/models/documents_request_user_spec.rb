RSpec.describe DocumentsRequestUser, type: :model do
  before do
    create_list(:campaign_channel, 5)
  end

  describe "associations" do
    subject(:documents_request_user) { build(:documents_request_user) }
    it { is_expected.to belong_to(:documents_request) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    context "when the user already has documents_request" do
      let(:documents_request_user) { create(:documents_request_user) }
      subject { build(:documents_request_user, documents_request: documents_request_user.documents_request, user: documents_request_user.user) }
      it { is_expected.not_to be_valid }
    end
  end

  Sidekiq::Testing.inline! do
    describe "#notify_recipient" do
      let(:documents_request_user) { build(:documents_request_user) }
      let(:mailer) { double("DocumentsRequestMailer") }

      before do
        allow(DocumentsRequestMailer).to receive(:notify_user).and_return(mailer)
        allow(mailer).to receive(:deliver_later)
      end

      it "sends a notification email to the recipient" do
        documents_request_user.send(:notify_recipient)
        expect(mailer).to have_received(:deliver_later)
      end
    end
  end
end
