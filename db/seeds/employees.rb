def seed_employees(companies)
  companies.each { |company| DemoData.employees(company) }
end
