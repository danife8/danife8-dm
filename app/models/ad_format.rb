class AdFormat < ApplicationRecord
  acts_as_paranoid

  scope :ordered, -> { order(position: :asc) }

  has_many :master_relationships, dependent: :restrict_with_error

  validates :position, presence: true, uniqueness: true, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :label, presence: true
  validates :value, presence: true, uniqueness: true
end
