class MediaPlan < ApplicationRecord
  include StateField

  has_paper_trail skip: %i[create_at updated_at]
  acts_as_paranoid

  scope :search_by_title, ->(query) { where("media_plans.title ILIKE ?", "%#{query}%") }
  scope :ordered, -> { order(created_at: :desc) }
  scope :by_aasm_states, ->(aasm_states) { where(aasm_state: aasm_states) }
  scope :by_client_ids, ->(client_ids) { where(client_id: client_ids) }
  scope :order_by, ->(field, direction) { order(field => direction) }
  scope :in_reviews, -> { where(aasm_state: [:in_review, :assigned_to_reviewer, :saved]) }
  scope :in_queue, -> { where(reviewer: nil) }
  scope :in_queue_first, -> { order(Arel.sql("reviewer_id IS NULL DESC")).ordered }

  belongs_to :client
  has_one :agency, through: :client
  belongs_to :media_mix
  belongs_to :reviewer, class_name: "User", optional: true
  belongs_to :creator, class_name: "User"
  has_one :media_brief, through: :media_mix
  has_many :insertion_orders
  has_one :media_plan_output, ->(record) { where(version: record.media_plan_output_version) }, dependent: :destroy
  accepts_nested_attributes_for :media_plan_output
  has_one_attached :ppt_file

  validates :title, presence: true

  before_update :review_notification
  before_update :validate_comments_for_approve_or_reject
  before_update :change_status_notification
  before_update :approval_needed_notification
  after_update :user_changed_status_notification
  before_update :create_insertion_order

  aasm column: "aasm_state" do
    state :created, initial: true
    state :in_review
    state :assigned_to_reviewer
    state :approved
    state :rejected

    # User events
    event :user_submit do
      before do
        user_waiting_for_review
      end

      transitions from: :created, to: :in_review
    end

    event :reviewer_assign do
      transitions from: :in_review, to: :assigned_to_reviewer
    end

    event :reviewer_approve do
      before do
        user_review
      end

      transitions from: :assigned_to_reviewer, to: :approved
    end

    event :reviewer_reject do
      transitions from: :assigned_to_reviewer, to: :rejected
    end
  end

  aasm :creator_state, column: "aasm_creator_state" do
    state :user_created, initial: true
    state :user_waiting_for_reviewer
    state :user_in_review
    state :user_approved
    state :user_rejected

    event :user_waiting_for_review do
      transitions from: :user_created, to: :user_waiting_for_reviewer
    end

    event :user_review do
      transitions from: [:user_created, :user_waiting_for_reviewer], to: :user_in_review
    end

    event :user_approve do
      transitions from: :user_in_review, to: :user_approved, guard: :approved?
    end

    event :user_reject do
      transitions from: :user_in_review, to: :user_rejected, guard: :approved?
    end
  end

  def self.valid_aasm_states
    %w[created in_review assigned_to_reviewer approved rejected]
  end

  def approve_associated_media
    approve_media_mix
    approve_media_brief
  end

  def approve_media_mix
    # In case the media mix is already approved, don't do anything
    media_mix.approve! if media_mix.may_approve?
  end

  def approve_media_brief
    # In case the media brief is already approved, don't do anything
    media_brief.approve! if media_brief.may_approve?
  end

  def generate_media_plan_output
    MediaPlans::GenerateMediaPlanOutput.new(self).call
  end

  def has_media_output?
    media_mix&.has_media_output? && media_plan_output.present?
  end

  private

  def change_status_notification
    return unless ["approved", "rejected"].include?(aasm_state)

    MediaPlanMailer.changed_status(id).deliver_later if will_save_change_to_aasm_state?
  end

  def review_notification
    return unless in_review?

    MediaPlanMailer.review_notification(id).deliver_later if will_save_change_to_aasm_state?
  end

  def approval_needed_notification
    return unless approved?

    MediaPlanMailer.approval_needed(id).deliver_later if will_save_change_to_aasm_state?
  end

  def user_changed_status_notification
    return unless ["user_approved", "user_rejected"].include?(aasm_creator_state)

    MediaPlanMailer.user_changed_status(id).deliver_later if saved_change_to_aasm_creator_state?
  end

  def create_insertion_order
    return unless user_approved?

    if will_save_change_to_aasm_creator_state?
      insertion_order = InsertionOrder.new(title: "IO - #{title}", media_plan: self, client:)
      unless insertion_order.save
        Rails.logger.error("Insertion order could not be created: #{insertion_order.errors.full_messages}")
      end
    end
  end

  def validate_comments_for_approve_or_reject
    validate_reviewer_comments if aasm_state_changed?
  end

  def validate_reviewer_comments
    if aasm_state == "approved" && approve_comment.blank?
      errors.add(:approve_comment, "can't be blank, please provide a comment or 'N/A'")
      throw(:abort)
    elsif aasm_state == "rejected" && reject_comment.blank?
      errors.add(:reject_comment, "can't be blank, please provide a comment or 'N/A'")
      throw(:abort)
    end
  end
end
