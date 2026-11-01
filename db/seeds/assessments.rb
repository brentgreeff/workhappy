# Ten years of a status column nobody constrained, and answers stored however the form of the
# day sent them. Skipped for any company that already has rows, so re-seeding changes nothing.
PER_COMPANY = 300

def seed_assessments(companies, anchor:)
  companies.each do |company|
    next if company.assessments.exists?

    rows = DemoData.assessment_rows(company, count: PER_COMPANY, rng: Random.new(company.id), anchor:)
    # Bypasses validations on purpose: these rows are the legacy data the validations will
    # later be written against.
    Assessment.insert_all(rows)
  end
end
