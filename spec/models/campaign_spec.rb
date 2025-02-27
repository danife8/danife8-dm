require "rails_helper"

describe Campaign, type: :model do
  describe "Associations" do
    it { should belong_to(:client).inverse_of(:campaigns) }
    it { should belong_to(:insertion_order) }
    it { should have_many(:documents).through(:insertion_order) }
    it { should have_one(:media_brief).through(:insertion_order) }
    it { should have_one(:media_mix).through(:insertion_order) }
    it { should have_one(:media_plan).through(:insertion_order) }
    it { should have_one(:documents_request).through(:insertion_order) }
  end
end
