# The five values production standardises on, and the legacy spellings that mean one of them.
# One mapping for filters, the export, the dashboard and the model's write path: the Arel below
# is generated from the same table, so Ruby and the database cannot disagree, and no SQL string
# is ever assembled from Ruby values.
module AssessmentStatus
  extend self

  CANONICAL = %w[pending in_progress completed needs_follow_up archived].freeze

  ALIASES = {
    "complete" => "completed",
    "comp" => "completed",
    "done" => "completed"
  }.freeze

  UNMAPPED = "unmapped"

  # Canonical value for a stored string, or nil when nothing maps: nil, "", "n/a" and anything
  # unknown stay unmapped on purpose; deciding what they mean is the business's call.
  def normalize(raw)
    cleaned = raw.to_s.strip.downcase
    return cleaned if CANONICAL.include?(cleaned)

    ALIASES[cleaned]
  end

  # Every lowercase spelling a filter for the canonical value must match.
  def spellings(canonical)
    [canonical, *ALIASES.select { |_, target| target == canonical }.keys]
  end

  # Every lowercase spelling that maps to something.
  def known_spellings
    CANONICAL + ALIASES.keys
  end

  def options
    CANONICAL.map { |value| [value.humanize, value] }
  end

  # LOWER(TRIM(status)): the legacy column as the mapping sees it.
  def lower_trim_status
    trimmed = Arel::Nodes::NamedFunction.new("TRIM", [Assessment.arel_table[:status]])
    Arel::Nodes::NamedFunction.new("LOWER", [trimmed])
  end

  # Rows whose legacy value maps to nothing. NULL NOT IN (...) is NULL, so NULL is spelled out.
  def unmapped_arel
    lower_trim_status.not_in(known_spellings).or(Assessment.arel_table[:status].eq(nil))
  end
end
