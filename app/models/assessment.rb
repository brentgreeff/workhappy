class Assessment < ApplicationRecord
  belongs_to :company
  belongs_to :employee

  # The composite foreign key enforces this at the database; the validation gives the
  # readable error.
  validate :employee_belongs_to_company

  private

  def employee_belongs_to_company
    return if employee.nil? || employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end
end
