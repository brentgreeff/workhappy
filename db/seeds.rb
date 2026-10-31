# Two tenants, one admin each. Sign in as either to see that the other's data never shows.
{
  "Harbour Logistics" => "admin@harbour.example",
  "Meridian Legal" => "admin@meridian.example"
}.each do |company_name, email_address|
  company = Company.find_or_create_by!(name: company_name)
  company.users.find_or_create_by!(email_address:) { |u| u.password = "password" }
end
