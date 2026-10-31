class Employee < ApplicationRecord
  belongs_to :company

  normalizes :email, with: ->(e) { e.strip.downcase }
  validates :name, :email, presence: true
end
