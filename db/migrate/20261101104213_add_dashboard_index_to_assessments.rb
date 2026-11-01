# The dashboard's one measured change: the page statement walks this index in order instead of
# reading every row of the company and sorting, and a date range becomes an index condition.
# Concurrent so the large table takes no lock while it builds; see SOLUTION.md for the numbers.
class AddDashboardIndexToAssessments < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :assessments, [:company_id, :created_at, :id], algorithm: :concurrently
  end
end
