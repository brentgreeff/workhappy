# Demo data only: two tenants with published passwords and invented assessments.
abort "Refusing to seed demo data into production" if Rails.env.production?

load Rails.root.join("db/seeds/employees.rb")
load Rails.root.join("db/seeds/assessments.rb")

# Fixed so the dataset is identical on every machine and every day.
ANCHOR = DemoData::ANCHOR

# Sign in as either admin to see that the other company's data never shows.
demo_companies = {
  "Harbour Logistics" => "admin@harbour.example",
  "Meridian Legal" => "admin@meridian.example"
}.map do |company_name, email_address|
  company = Company.find_or_create_by!(name: company_name)
  company.users.find_or_create_by!(email_address:) { |u| u.password = "password" }
  company
end

seed_employees(demo_companies)
seed_assessments(demo_companies, anchor: ANCHOR)
