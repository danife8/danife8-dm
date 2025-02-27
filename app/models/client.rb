require "devise"
require "uri"

# Manages client data and helper methods.
class Client < ApplicationRecord
  acts_as_paranoid

  scope :search_by_name, ->(query) {
    if query.present?
      where("name ILIKE ?", "%#{query}%")
    else
      where(name: nil)
    end
  }
  scope :by_agency_id, ->(agency_id) { where(agency_id:) }
  scope :ordered, -> { order(name: :asc) }

  belongs_to :agency, inverse_of: :clients
  has_many :users, inverse_of: :client
  has_one :media_plan
  has_many :media_brief_builders, inverse_of: :client, dependent: :destroy
  has_many :media_briefs, inverse_of: :client, dependent: :destroy
  has_many :media_mixes, dependent: :destroy
  has_many :campaigns, inverse_of: :client
  has_many :documents_requests, through: :campaigns
  has_many :documents_request_users, through: :documents_requests
  has_and_belongs_to_many :owner_users,
    class_name: "User",
    join_table: "clients_users",
    association_foreign_key: "user_id",
    foreign_key: "client_id"

  before_validation { self.name = name&.strip }
  before_validation { self.contact_first_name = contact_first_name&.strip }
  before_validation { self.contact_last_name = contact_last_name&.strip }
  before_validation { self.contact_email = contact_email&.strip&.downcase }
  before_validation { self.contact_position = nil if contact_position == "" }
  before_validation { self.contact_position = contact_position&.strip }
  before_validation { self.contact_phone_number = nil if contact_phone_number == "" }
  before_validation { self.contact_phone_number = contact_phone_number&.strip&.delete("+() -.") }
  before_validation { self.website = website&.strip&.downcase }

  validates :name,
    presence: true,
    uniqueness: {scope: :agency}
  validates_presence_of :contact_first_name, :contact_last_name
  validates :contact_email,
    presence: true,
    format: {with: Devise.email_regexp}
  validates :contact_phone_number,
    numericality: true,
    length: {is: 10},
    allow_nil: true
  validates :website,
    presence: true,
    format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https])}

  delegate :name,
    to: :agency,
    prefix: true

  # @return [String]
  def contact_full_name
    "#{contact_first_name} #{contact_last_name}".strip
  end
end
