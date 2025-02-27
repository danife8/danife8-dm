require "rails_helper"
require "webmock/rspec"

describe InsertionOrder, type: :model do
  let(:client) { create(:client) }
  let(:media_plan) { create(:media_plan, client:) }
  let(:insertion_order) { build(:insertion_order, title: "IO - 1", media_plan:, client:) }

  before do
    create_list(:campaign_channel, 5)
  end

  describe "Validations" do
    it { should validate_presence_of(:title) }
  end

  describe "Associations" do
    it { should belong_to(:client) }
    it { should belong_to(:media_plan) }
    it { should have_one(:agency).through(:client) }
    it { should have_one(:media_mix).through(:media_plan) }
    it { should have_one(:media_brief).through(:media_mix) }
    it { should have_one(:signature_request).dependent(:destroy) }
    it { should have_one(:campaign).dependent(:destroy) }
  end

  describe "search_by_title scope" do
    let!(:io_1) { create(:insertion_order, title: "IO - 1") }
    let!(:io_2) { create(:insertion_order, title: "IO - 2") }
    let!(:io_3) { create(:insertion_order, title: "IO - 3") }

    it "returns insertion orders containing the search query in title" do
      expect(described_class.search_by_title("IO - 1")).to contain_exactly(io_1)
    end

    it "does not return insertion orders not containing the search query in title" do
      expect(described_class.search_by_title("IO - 1")).not_to include(io_2, io_3)
    end
  end

  describe "order_by scope" do
    let!(:io_1) { create(:insertion_order, title: "IO - B", created_at: 2.days.ago) }
    let!(:io_2) { create(:insertion_order, title: "IO - A", created_at: 1.day.ago) }

    context "when sorting by created_at" do
      it "sorts in ascending order" do
        ordered_insertion_orders = InsertionOrder.order_by("created_at", "asc")
        expect(ordered_insertion_orders.first).to eq(io_1)
      end

      it "sorts in descending order" do
        ordered_insertion_orders = InsertionOrder.order_by("created_at", "desc")
        expect(ordered_insertion_orders.first).to eq(io_2)
      end
    end

    context "when sorting by other fields" do
      let!(:io_3) { create(:insertion_order, title: "IO - C") }
      let!(:io_4) { create(:insertion_order, title: "IO - D") }

      it "sorts in ascending order ignoring case" do
        ordered_insertion_orders = InsertionOrder.order_by("title", "asc")
        expect(ordered_insertion_orders).to eq([io_2, io_1, io_3, io_4])
      end

      it "sorts in descending order ignoring case" do
        ordered_insertion_orders = InsertionOrder.order_by("title", "desc")
        expect(ordered_insertion_orders).to eq([io_4, io_3, io_1, io_2])
      end
    end
  end

  describe "callbacks" do
    it "calls review_notification after create" do
      expect_any_instance_of(InsertionOrder).to receive(:review_notification)
      insertion_order.save
    end

    it "calls generate_and_upload_pdf after create_commit" do
      expect_any_instance_of(InsertionOrder).to receive(:generate_and_upload_pdf)
      insertion_order.save
    end

    it "calls create_campaign after create" do
      expect_any_instance_of(InsertionOrder).to receive(:create_campaign)
      insertion_order.save
    end
  end

  describe "#create_campaign" do
    it "create a campaign after create" do
      insertion_order.save
      expect(insertion_order.campaign).to_not be_nil
    end
  end

  describe "#generate_and_upload_pdf" do
    let(:pdf_service) { instance_double(InsertionOrders::GeneratePdf) }
    let(:upload_service) { instance_double(InsertionOrders::DropboxSignUploadPdf) }
    let(:pdf_file) { Tempfile.new(["unsigned_io_test", ".pdf"], Rails.root.join("tmp")) }
    let(:api_url) { "https://api.hellosign.com/v3/signature_request/send" }

    before do
      allow(InsertionOrders::GeneratePdf).to receive(:new).and_return(pdf_service)
      allow(pdf_service).to receive(:call).and_return(pdf_file)
      allow(InsertionOrders::DropboxSignUploadPdf).to receive(:new).and_return(upload_service)
      allow(upload_service).to receive(:call).and_return(double(signature_request: double(signature_request_id: "12345")))

      # Stub the request to the Dropbox Sign API
      stub_request(:post, api_url)
        .to_return(
          status: 200,
          body: {signature_request: {signature_request_id: "12345"}}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
    end

    it "generates and uploads PDF" do
      insertion_order.save
      expect(pdf_service).to have_received(:call)
      expect(upload_service).to have_received(:call)
    end

    it "creates a signature request" do
      insertion_order.save
      expect(insertion_order.signature_request).to be_present
      expect(insertion_order.signature_request.signature_request_id).to eq("12345")
    end
  end
end
