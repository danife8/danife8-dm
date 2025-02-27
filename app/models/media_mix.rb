class MediaMix < ApplicationRecord
  include StateField

  has_paper_trail skip: %i[create_at updated_at]
  acts_as_paranoid

  scope :search_by_title, ->(query) { where("media_mixes.title ILIKE ?", "%#{query}%") }
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_client_id, ->(client_id) { where(client_id:) }
  scope :by_aasm_states, ->(aasm_states) { where(aasm_state: aasm_states) }
  scope :by_client_ids, ->(client_ids) { where(client_id: client_ids) }
  scope :order_by, ->(field, direction) { order(field => direction) }

  belongs_to :client
  belongs_to :media_brief, inverse_of: :media_mixes
  has_many :media_plans, dependent: :destroy
  has_one :media_output, ->(record) { where(version: record.media_output_version) }, dependent: :destroy

  has_one_attached :ppt_file

  before_save :modify, if: [:persisted?, :active?, :has_changes_to_save?]

  validates :title, presence: true

  # Define state machine values and state change events.
  aasm column: "aasm_state" do
    state :active, initial: true
    state :modified
    state :approved

    event :activate do
      transitions from: :modified, to: :active
    end

    event :modify do
      transitions from: :active, to: :modified
    end

    event :approve do
      transitions from: [:active, :modified], to: :approved
    end
  end

  # Supported state machine values
  def self.valid_aasm_states
    %w[active modified approved].freeze
  end

  def generate_media_output
    MediaMixes::GenerateMediaOutput.new(self).call
  end

  def has_media_output?
    media_output.present?
  end
end
