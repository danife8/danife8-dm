require "uri"

# Manages fully completed media brief data for use downstream.
class MediaBrief < ApplicationRecord
  include StateField
  include MediaBriefValidationHelpers
  include MediaBriefCommonHelpers
  include MediaBriefGeographicTargeting

  has_paper_trail skip: %i[create_at updated_at]
  acts_as_paranoid

  scope :by_client_id, ->(client_id) { where(client_id:) }
  scope :ordered, -> { order(created_at: :desc) }

  scope :search_by_title, ->(query) {
    if query.present?
      where("title ILIKE ?", "%#{query}%")
    else
      where(title: nil)
    end
  }

  scope :by_aasm_states, ->(aasm_states) { where(aasm_state: aasm_states) }
  scope :by_client_ids, ->(client_ids) { where(client_id: client_ids) }
  scope :order_by, ->(field, direction) { order(field => direction) }

  belongs_to :client, inverse_of: :media_briefs
  belongs_to :media_brief_builder, inverse_of: :media_brief
  belongs_to :campaign_objective
  belongs_to :campaign_initiative
  has_one :media_plan
  has_many :geographic_filters, inverse_of: :geographic_filterable
  has_many :media_mixes, inverse_of: :media_brief, dependent: :destroy

  accepts_nested_attributes_for :geographic_filters, allow_destroy: true

  has_one_attached :campaign_data
  has_one_attached :customer_data

  # Convert string values in hash to boolean
  cast_boolean_in_hash :social_platforms
  cast_boolean_in_hash :social_advertising_access
  cast_boolean_in_hash :demographic_genders
  cast_boolean_in_hash :demographic_ages
  cast_boolean_in_hash :geographic_targets
  cast_boolean_in_hash :creative_assets
  cast_boolean_in_hash :campaign_channels

  # Data cleanup prior to validation.
  before_validation { self.title = title&.strip }
  before_validation { self.destination_url = destination_url&.strip&.downcase }
  before_validation { self.industry_target = industry_target&.strip&.downcase }
  before_validation { self.industry_description1 = industry_description1&.strip }
  before_validation { self.industry_description2 = industry_description2&.strip }
  before_validation { self.industry_description3 = industry_description3&.strip }
  before_validation { self.industry_description4 = industry_description4&.strip }
  before_validation { self.industry_description5 = industry_description5&.strip }
  before_validation { self.demographic_details1 = demographic_details1&.strip }
  before_validation { self.demographic_details2 = demographic_details2&.strip }
  before_validation { self.demographic_details3 = demographic_details3&.strip }
  before_validation { self.demographic_details4 = demographic_details4&.strip }
  before_validation { self.demographic_details5 = demographic_details5&.strip }
  before_validation { self.tracking_capability = tracking_capability&.strip&.downcase }
  before_validation do
    self.other_tracking_capability = (tracking_capability == "other") ? other_tracking_capability&.strip : ""
  end

  before_save :modify, if: [:active?, :has_changes_to_save?, :non_skip_modify]
  after_update :regenerate_if_campaign_budget_changed

  # Validate all inbound data.
  validates_uniqueness_of :media_brief_builder
  validate :completed_media_brief_builder
  validates_presence_of :title
  validate :campaign_initiative_scoped_to_objective
  validates_presence_of :campaign_starts_on
  validates :campaign_ends_on,
    presence: true,
    comparison: {greater_than_or_equal_to: :campaign_starts_on}
  validates :campaign_budget,
    presence: true,
    numericality: {only_integer: true, greater_than_or_equal_to: 100}
  validates :destination_url,
    presence: true,
    format: {with: URI::DEFAULT_PARSER.make_regexp(%w[http https])}
  validates_presence_of :social_platforms, :social_advertising_access
  validate :social_platforms_hash
  validate :social_advertising_access_hash
  validates :industry_target,
    presence: true,
    inclusion: {in: IndustryTarget.all.map(&:value)}
  validates_presence_of :industry_description1
  validates_inclusion_of :all_demographics, in: [true, false]
  validates_presence_of :demographic_genders, :demographic_ages
  validates_presence_of :demographic_details1
  validates_presence_of :demographic_details2
  validates_presence_of :demographic_details3
  validate :demographic_genders_hash
  validate :demographic_ages_hash

  attr_writer :state, :city_state, :address, :zipcode, :local_city_state
  attr_accessor :skip_before_save_modify

  validates_presence_of :geographic_targets
  validate :geographic_targets_hash
  validate :geographic_filters_details

  validates :previous_campaign_data, :previous_customer_data,
    presence: true,
    inclusion: {in: MediaBriefPreviousData.all.map(&:value)}
  validates_inclusion_of :tracking_pixel_access, in: [true, false]

  validates :tracking_capability,
    presence: true,
    inclusion: {in: TrackingCapability.all.map(&:value)}
  validates_presence_of :other_tracking_capability,
    if: -> { tracking_capability == "other" }
  validates_presence_of :creative_assets, :campaign_channels
  validate :creative_assets_hash
  validate :campaign_channels_hash

  # Define state machine values and state change events.
  aasm do
    state :active, initial: true
    state :modified
    state :approved

    event :activate do
      before do
        self.skip_before_save_modify = true
      end

      transitions from: [:modified], to: :active
    end

    event :modify do
      transitions from: [:active, :modified], to: :modified
    end

    event :approve do
      transitions from: [:active, :modified], to: :approved
    end
  end

  # Supported state machine values
  def self.valid_aasm_states
    %w[active modified approved].freeze
  end

  def current_step_was
    8
  end

  # @return [MediaMix,NilClass]
  def newest_media_mix
    media_mixes.last
  end

  def update_initial_state(state = :active)
    # Skips versioning for the initial state update of the media brief
    skip_paper_trail_versioning do
      self.class.skip_callback(:save, :before, :modify)
      update(aasm_state: state)
      self.class.set_callback(:save, :before, :modify)
    end
  end

  protected

  def non_skip_modify
    !skip_before_save_modify
  end

  def skip_paper_trail_versioning
    # Temporarily disables PaperTrail versioning for the current model
    PaperTrail.request.disable_model(self.class.name)
    yield if block_given?
  ensure
    PaperTrail.request.enable_model(self.class.name)
  end

  # Verify that the media brief builder has been completed.
  def completed_media_brief_builder
    unless media_brief_builder&.completed?
      errors.add(:media_brief_builder, "must be completed")
    end
  end

  def regenerate_if_campaign_budget_changed
    return unless saved_change_to_campaign_budget?

    transaction do
      media_mixes.each do |mx|
        mx.generate_media_output

        mx.media_plans.each do |mp|
          mp.generate_media_plan_output
        end
      end
    rescue ActiveRecord::ActiveRecordError
      raise ActiveRecord::Rollback, "Error regenerating media mixes and media plans"
    end
  end
end
