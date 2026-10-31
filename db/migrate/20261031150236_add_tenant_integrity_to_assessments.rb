class AddTenantIntegrityToAssessments < ActiveRecord::Migration[8.1]
  def change
    # Postgres only lets a foreign key point at a unique column set, so the pair has to be
    # declared unique even though id already is.
    add_index :employees, [:id, :company_id], unique: true

    # An assessment may only reference an employee of its own company.
    remove_foreign_key :assessments, :employees
    add_foreign_key :assessments, :employees,
      column: [:employee_id, :company_id], primary_key: [:id, :company_id]
  end
end
