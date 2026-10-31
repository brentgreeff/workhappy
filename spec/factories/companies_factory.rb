FactoryBot.define do
  sequence(:company_name) { |n| "Company #{n}" }

  factory :company do
    name { generate(:company_name) }
  end
end
