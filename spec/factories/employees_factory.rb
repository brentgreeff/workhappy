FactoryBot.define do
  factory :employee do
    company
    sequence(:name) { |n| "Employee #{n}" }
    sequence(:email) { |n| "employee#{n}@example.com" }
  end
end
