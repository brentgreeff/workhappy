class User < ApplicationRecord
  has_secure_password
  belongs_to :company
  has_many :sessions, dependent: :destroy
  has_many :exports, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, uniqueness: true
end
