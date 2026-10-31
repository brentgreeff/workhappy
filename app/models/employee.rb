class Employee < ApplicationRecord
  belongs_to :company
  has_many :assessments, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }
  validates :name, :email, presence: true
end
