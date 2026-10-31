class Company < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :employees, dependent: :destroy
  has_many :assessments, dependent: :destroy

  validates :name, presence: true
end
