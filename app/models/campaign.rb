class Campaign < ApplicationRecord
  ## ASSOCIATIONS
  belongs_to :client, inverse_of: :campaigns
  belongs_to :insertion_order
  has_many :documents, through: :insertion_order
  has_one :media_brief, through: :insertion_order
  has_one :media_mix, through: :insertion_order
  has_one :media_plan, through: :insertion_order
  has_one :documents_request, through: :insertion_order

  ## SCOPES
  scope :by_client_ids, ->(client_ids) { where(client_id: client_ids) }
  scope :search_by_title, ->(query) { where("insertion_orders.title ILIKE ?", "%#{query}%") }
  scope :ordered, -> { order(created_at: :desc) }
  scope :order_by, ->(field, direction) { order("insertion_orders.title" => direction) }

  ## CLASS METHODS
  def self.valid_aasm_states
    []
  end
end
