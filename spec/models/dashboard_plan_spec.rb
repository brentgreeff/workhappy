require 'rails_helper'

# The guard for the Task 2 index: the page statement must walk the company/date index rather
# than read every row of the company and sort. Written before the migration, failing.
RSpec.describe 'dashboard page plan' do
  it 'walks the company/date index instead of sorting every row' do
    company = create(:company)
    DemoData.employees(company)
    Assessment.insert_all(DemoData.assessment_rows(company, count: 2_000, rng: Random.new(1)))
    ActiveRecord::Base.connection.execute('ANALYZE assessments')

    sql = company.assessments.order(created_at: :desc, id: :desc).limit(50).to_sql
    plan = ActiveRecord::Base.connection.explain(sql)

    expect(plan).to include('index_assessments_on_company_id_and_created_at')
    expect(plan).not_to include('Sort')
  end
end
