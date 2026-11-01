class Export < ApplicationRecord
  belongs_to :company
  belongs_to :user
  has_one_attached :file, dependent: :purge_later

  enum :status, { queued: "queued", processing: "processing", ready: "ready", failed: "failed" }, default: :queued

  normalizes :status_filter, with: ->(s) { s.presence }
  validates :status_filter, inclusion: { in: AssessmentFilter::STATUSES }, allow_nil: true
  validate :filter_is_valid

  # Built fresh each time from the columns, so it always reflects the current attributes.
  def filter
    AssessmentFilter.new(from_date:, to_date:, status: status_filter)
  end

  # The rows the file will hold. Always the export's own company; the filter only narrows.
  # No order here: the job reads it with find_each, which batches by id.
  def assessments
    filter.apply(company.assessments)
  end

  def filename
    "assessments-#{id}.csv"
  end

  private

  def filter_is_valid
    current = filter
    errors.merge!(current.errors) unless current.valid?
  end
end
