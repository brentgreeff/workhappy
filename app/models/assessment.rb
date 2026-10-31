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

  # The two filters the brief allows. Dates are whole days in the app zone; the end is
  # inclusive, done as an exclusive bound on the next midnight so an index on created_at works.
  scope :created_from, ->(date) { where(created_at: date.in_time_zone..) }
  scope :created_through, ->(date) { where(created_at: ...(date + 1).in_time_zone) }
  # Until the backfill runs, rows still carry legacy spellings and odd casing, so a filter for
  # a canonical status has to match all of them.
  scope :with_status, ->(canonical) { where("LOWER(TRIM(status)) IN (?)", AssessmentStatus.spellings(canonical)) }

  # The composite foreign key enforces this at the database; the validation gives the
  # readable error.
  validate :employee_belongs_to_company

  def canonical_status
    AssessmentStatus.normalize(status) || AssessmentStatus::UNMAPPED
  end

  private

  def employee_belongs_to_company
    return if employee.nil? || employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end
end
