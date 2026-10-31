FactoryBot.define do
  factory :export do
    user
    company { user.company }
  end
end
