# Manages agency data to scope other resources.
class Agency < ApplicationRecord
  acts_as_paranoid

  has_many :clients, inverse_of: :agency
  has_many :users, inverse_of: :agency
  has_many :media_plans, through: :clients
  has_many :media_brief_builders, through: :clients
  has_many :media_mixes, through: :clients

  validates :name,
    presence: true,
    uniqueness: true
end
