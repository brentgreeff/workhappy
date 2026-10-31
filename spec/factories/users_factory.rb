FactoryBot.define do
  factory :user do
    transient do
      company_name { generate(:company_name) }
    end

    company { association :company, name: company_name }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { 'password' }
  end
end
