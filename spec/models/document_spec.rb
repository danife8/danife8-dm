require "rails_helper"

RSpec.describe Document, type: :model do
  let(:client) { create(:client) }
  let(:media_plan) { create(:media_plan, client:) }
  let(:insertion_order) { build(:insertion_order, title: "IO - 1", media_plan:, client:) }

  before do
    create_list(:campaign_channel, 5)
  end

  let(:valid_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf") }
  let(:invalid_file_type) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.xml"), "application/xml") }
  let(:large_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/sample_26mb.pdf"), "application/pdf") }

  subject(:document) { described_class.new(insertion_order: insertion_order) }

  context "with valid file" do
    before do
      subject.file.attach(valid_file)
      subject.save
    end

    it "returns title" do
      expect(subject.title).to eq(File.basename(valid_file.original_filename.to_s, ".*"))
    end

    it "returns valid document" do
      expect(subject).to be_valid
    end
  end

  context "with invalid file" do
    it "is invalid with an unsupported file type" do
      subject.file.attach(invalid_file_type)
      subject.save
      expect(subject.errors[:base]).to include("#{invalid_file_type.original_filename} error: Invalid file Content-Type")
    end

    it "is invalid with a file larger than 25MB" do
      subject.file.attach(large_file)
      subject.save
      expect(subject.errors[:base]).to include("#{large_file.original_filename} error: Size should be less than 25MB")
    end
  end

  describe "#destroy" do
    let!(:document) { create(:document, insertion_order: insertion_order) }
    subject { document.destroy }

    it "destroys the record and uploaded file" do
      expect(document.file).to be_attached
      expect { subject }.to change(Document, :count).by(-1)
    end
  end
end
