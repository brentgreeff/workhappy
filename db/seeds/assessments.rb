# Ten years of a status column nobody constrained, and answers stored however the form of the
# day sent them. Deterministic (fixed RNG seed) and skipped for any company that already has
# rows, so re-seeding changes nothing.
PER_COMPANY = 300

# The brief's observed values, weighted so the canonical five dominate. "cancelled" is the
# one value no mapping will know, so the unmapped bucket has something in it.
STATUSES = [
  ["completed", 30], ["pending", 12], ["in_progress", 10], ["needs_follow_up", 6], ["archived", 8],
  ["complete", 8], ["comp", 3], ["done", 6], ["Complete", 2],
  ["n/a", 3], ["", 3], [nil, 4], ["cancelled", 1]
].freeze

QUESTIONS = %w[posture screen chair breaks lighting].freeze

COMMENTS = [
  nil, nil, nil, "All fine", "Chair is too low", "Need a second monitor",
  "Back pain after long calls", "Call me on 07700 900123 to arrange a visit",
  "Shared desk, nothing to adjust", "Standing desk requested"
].freeze

def weighted_status(rng)
  roll = rng.rand(STATUSES.sum { |_, weight| weight })
  STATUSES.each do |status, weight|
    return status if roll < weight
    roll -= weight
  end
end

# Mostly clean integers 1..5; the rest is what a decade of form changes left behind.
def answer(rng)
  case rng.rand(100)
  when 0...80 then rng.rand(1..5)
  when 80...90 then rng.rand(1..5).to_s
  when 90...96 then nil
  else :missing
  end
end

def responses(rng)
  return nil if rng.rand(100) < 3
  return {} if rng.rand(100) < 3

  answers = QUESTIONS.to_h { |q| [q, answer(rng)] }.reject { |_, v| v == :missing }
  answers["comments"] = COMMENTS[rng.rand(COMMENTS.size)]
  answers
end

Company.find_each do |company|
  next if company.assessments.exists?

  rng = Random.new(company.id)
  employees = company.employees.to_a
  now = Time.current

  rows = Array.new(PER_COMPANY) do
    employee = employees[rng.rand(employees.size)]
    created_at = now - rng.rand(0...(6 * 365)).days - rng.rand(0...86_400).seconds
    {
      company_id: company.id,
      employee_id: employee.id,
      employee_email: employee.email,
      status: weighted_status(rng),
      responses_json: responses(rng),
      created_at:,
      updated_at: created_at
    }
  end

  Assessment.insert_all(rows)
end
