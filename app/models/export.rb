class Export < ApplicationRecord
  belongs_to :company
  belongs_to :user
  has_one_attached :file, dependent: :purge_later

  enum :status, { queued: "queued", processing: "processing", ready: "ready", failed: "failed" }, default: :queued

  normalizes :status_filter, with: ->(s) { s.presence }
  validates :status_filter, inclusion: { in: AssessmentStatus::CANONICAL }, allow_nil: true
  validate :range_in_order

  # The rows the file will hold. Always the export's own company; the filters only narrow.
  # No order here: the job reads it with find_each, which batches by id.
  def assessments
    scope = company.assessments
    scope = scope.created_from(from_date) if from_date
    scope = scope.created_through(to_date) if to_date
    scope = scope.with_status(status_filter) if status_filter
    scope
  end

  def filename
    "assessments-#{id}.csv"
  end

  private

  def range_in_order
    return unless from_date && to_date && to_date < from_date

    errors.add(:to_date, "must be on or after From")
  end
end
