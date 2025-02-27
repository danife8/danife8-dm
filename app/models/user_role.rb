# Manages user roles and their helper methods.
class UserRole < ApplicationRecord
  has_many :users, inverse_of: :user_role

  scope :not_reviewer, -> { where.not(name: "reviewer") }

  validates :name,
    presence: true,
    uniqueness: true
  validates_presence_of :label

  def self.client_user
    find_by(name: "client_user")
  end
end
