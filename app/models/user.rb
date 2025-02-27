# frozen_string_literal: true

# Manages users data and helper methods.
class User < ApplicationRecord
  include StateField

  acts_as_paranoid

  scope :search_by_email, ->(query) {
    if query.present?
      where("email ILIKE ?", "%#{query}%")
    else
      where(email: nil)
    end
  }

  scope :reviewers, -> { joins(:user_role).where(user_role: {name: "reviewer"}) }
  scope :agency_users, -> { joins(:user_role).where(user_role: {name: "agency_user"}) }

  belongs_to :agency, inverse_of: :users
  belongs_to :user_role, inverse_of: :users
  belongs_to :client, optional: true, inverse_of: :users # Client association, only for Client Users
  has_many :media_plans, foreign_key: "reviewer_id"
  has_many :own_media_plans, class_name: "MediaPlan", foreign_key: "creator_id"
  has_many :export_logs
  has_and_belongs_to_many :reporting_dashboards, join_table: "reporting_dashboards_users"
  has_many :documents_request_users
  has_many :documents_requests, through: :documents_request_users
  has_many :campaigns, through: :documents_requests
  has_and_belongs_to_many :own_clients,
    class_name: "Client",
    join_table: "clients_users",
    association_foreign_key: "client_id",
    foreign_key: "user_id"

  devise :confirmable,
    :database_authenticatable,
    :invitable,
    :lockable,
    :recoverable,
    :registerable,
    :rememberable,
    :timeoutable,
    :trackable,
    :validatable

  before_validation { self.first_name = first_name&.strip }
  before_validation { self.last_name = last_name&.strip }
  before_validation { self.phone_number = phone_number&.strip&.delete("+() -.") }
  before_save :clear_client_if_not_client_user_role

  validates_presence_of :first_name, :last_name
  validates :phone_number,
    presence: true,
    numericality: true,
    length: {is: 10}
  validates_inclusion_of :super_admin, in: [true, false]
  validates :client_id,
    presence: true,
    if: -> { user_role.present? && client_user? }

  before_destroy { |record| record.disable! unless record.inactive? }

  # Define state machine values and state change events.
  aasm do
    state :pending, initial: true
    state :active, :inactive

    event :enable do
      transitions from: [:pending, :inactive], to: :active
    end

    event :disable do
      transitions from: [:pending, :active], to: :inactive
    end
  end

  delegate :name,
    to: :agency,
    prefix: true

  delegate :label,
    :name,
    to: :user_role,
    prefix: true

  delegate :clients,
    to: :agency,
    prefix: true

  delegate :name,
    to: :client,
    prefix: true,
    allow_nil: true

  %w[
    admin
    account_manager
    campaign_manager
    reviewer
    employee
    agency_admin
    agency_user
    client_user
  ].each do |role_name|
    # @return [TrueClass,FalseClass]
    define_method(:"#{role_name}?") do
      user_role_name == role_name
    end
  end

  # @return [String] first + last name
  def full_name
    "#{first_name} #{last_name}".strip
  end

  # Supported state machine values
  def self.valid_aasm_states
    %w[pending active inactive].freeze
  end

  def client_document_request_campaigns
    campaigns.where(client:)
  end

  protected

  # Override devise method to send emails async.
  # @see https://github.com/heartcombo/devise#activejob-integration
  def send_devise_notification(notification, *)
    devise_mailer.send(notification, self, *).deliver_later
  end

  private

  def clear_client_if_not_client_user_role
    self.client = nil if user_role.present? && !client_user?
  end
end
