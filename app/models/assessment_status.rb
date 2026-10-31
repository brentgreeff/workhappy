# The five values production standardises on, and the legacy spellings that mean one of them.
# One mapping for filters, the export, the dashboard and, later, writes and the backfill.
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
  # unknown stay unmapped on purpose; deciding what they mean is the backfill's job.
  def normalize(raw)
    cleaned = raw.to_s.strip.downcase
    return cleaned if CANONICAL.include?(cleaned)

    ALIASES[cleaned]
  end

  # Every lowercase spelling a filter for the canonical value must match.
  def spellings(canonical)
    [canonical, *ALIASES.select { |_, target| target == canonical }.keys]
  end

  def options
    CANONICAL.map { |value| [value.humanize, value] }
  end
end
