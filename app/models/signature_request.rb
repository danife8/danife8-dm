class SignatureRequest < ApplicationRecord
  include StateField

  belongs_to :insertion_order
  has_one_attached :signed_document
  has_one_attached :unsigned_document

  validates :signature_request_id, presence: true, uniqueness: true

  aasm column: "aasm_state" do
    state :unsigned, initial: true
    state :completed

    event :complete do
      transitions from: :unsigned, to: :completed
    end
  end

  def self.valid_aasm_states
    %w[unsigned completed].freeze
  end
end
