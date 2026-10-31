class Assessment < ApplicationRecord
  belongs_to :company
  belongs_to :employee

  # Shapes a decade of forms left in responses_json. jsonb_each raises on anything but an
  # object, so every per-answer query starts from with_response_object.
  scope :with_response_object, -> { where("jsonb_typeof(responses_json) = 'object'") }
  scope :with_non_object_responses, -> { where.not(responses_json: nil).where("jsonb_typeof(responses_json) <> 'object'") }
  scope :with_empty_responses, -> { where("responses_json = '{}'::jsonb") }
  scope :joins_each_response, -> { joins("CROSS JOIN LATERAL jsonb_each(assessments.responses_json)") }
  scope :grouped_by_response_key_and_type, -> { group("key", "jsonb_typeof(value)") }

  # The composite foreign key enforces this at the database; the validation gives the
  # readable error.
  validate :employee_belongs_to_company

  private

  def employee_belongs_to_company
    return if employee.nil? || employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end
end
