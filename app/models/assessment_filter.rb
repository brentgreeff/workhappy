# The two filters the brief allows, parsed and validated in one place and applied the same way
# by the dashboard and the export, so the page and the file can never disagree.
class AssessmentFilter
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATUSES = (AssessmentStatus::CANONICAL + [AssessmentStatus::UNMAPPED]).freeze

  attribute :from_date, :date
  attribute :to_date, :date
  attribute :status, :string

  # The span of the company's data, shown in the form when no dates are given. Display only:
  # apply ignores it, because blank dates already mean all time.
  attr_accessor :earliest, :latest

  validates :status, inclusion: { in: STATUSES }, allow_blank: true
  validate :dates_parse, :range_in_order

  def apply(scope)
    scope = scope.created_from(from_date) if from_date
    scope = scope.created_through(to_date) if to_date
    scope = status == AssessmentStatus::UNMAPPED ? scope.unmapped : scope.with_status(status) if status.present?
    scope
  end

  def shown_from_date = from_date || earliest&.to_date
  def shown_to_date = to_date || latest&.to_date

  def to_params
    { from_date:, to_date:, status: }.compact_blank
  end

  # The five canonical values plus "Unmapped", so rows the backfill could not resolve stay
  # reachable on the dashboard and in the export instead of silently vanishing.
  def self.options
    AssessmentStatus.options + [["Unmapped", AssessmentStatus::UNMAPPED]]
  end

  private

  # The date type casts garbage to nil, which would silently widen the query.
  def dates_parse
    %i[from_date to_date].each do |name|
      raw = @attributes[name.to_s].value_before_type_cast
      errors.add(name, "is not a date") if raw.present? && public_send(name).nil?
    end
  end

  def range_in_order
    return unless from_date && to_date && to_date < from_date

    errors.add(:to_date, "must be on or after From")
  end
end
