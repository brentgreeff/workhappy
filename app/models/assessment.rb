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
  # Status lives in two columns while the normalisation is in flight: status_v2 holds a
  # canonical value for rows written since the change or backfilled; the legacy column is
  # matched by spelling for the rest. The OR goes once the backfill has run.
  scope :with_status, ->(canonical) {
    where(status_v2: canonical)
      .or(where(status_v2: nil).where("LOWER(TRIM(status)) IN (?)", AssessmentStatus.spellings(canonical)))
  }
  scope :unmapped, -> { where(status_v2: nil).where(AssessmentStatus.unmapped_arel) }

  # The composite foreign key enforces this at the database; the validation gives the
  # readable error.
  validate :employee_belongs_to_company

  # Going forward, status_v2 is derived from whatever was written to status and must be one of
  # the five. Only when the status is being set: an unrelated edit to a legacy row whose value
  # maps to nothing is allowed and leaves status_v2 NULL, visibly unmapped, rather than refused
  # or guessed. Deriving on every save would also wipe a value the backfill had filled.
  before_validation :derive_status_v2, if: :status_being_set?
  validate :status_maps_to_canonical, if: :status_being_set?

  def canonical_status
    status_v2 || AssessmentStatus.normalize(status) || AssessmentStatus::UNMAPPED
  end

  # 0 to 100, or nil when the answers are too thin or too broken to score; unscored_reason says which.
  def score
    AssessmentScoring.score(responses_json)
  end

  def unscored_reason
    AssessmentScoring.reason(responses_json)
  end

  private

  def employee_belongs_to_company
    return if employee.nil? || employee.company_id == company_id

    errors.add(:employee, "must belong to the same company")
  end

  def status_being_set?
    new_record? || will_save_change_to_status?
  end

  def derive_status_v2
    self.status_v2 = AssessmentStatus.normalize(status)
  end

  # On :status, not :status_v2: the caller set status. The raw value is quoted so the message
  # says what was rejected.
  def status_maps_to_canonical
    return if AssessmentStatus::CANONICAL.include?(status_v2)

    errors.add(:status, "#{status.inspect} is not one of #{AssessmentStatus::CANONICAL.join(', ')}")
  end
end
