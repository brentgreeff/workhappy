# The demo data generator, shared by db/seeds and assessments:seed_large so a 300-row demo tenant
# and a 200,000-row benchmark tenant carry the same decade of mess. Deterministic: the RNG is
# seeded by the caller and dates hang off a fixed anchor.
module DemoData
  extend self

  ANCHOR = Time.utc(2026, 10, 31, 12)

  FIRST_NAMES = %w[
    Amara Ben Chloe Daniel Esme Farid Grace Hugo Imani Jonas Keira Liam Maya Noor Oscar
    Priya Quinn Rosa Samir Tessa Umar Vera Will Xiu Yusuf Zara
  ].freeze

  LAST_NAMES = %w[
    Adeyemi Brooks Chen Dlamini Evans Fischer Gupta Howard Ibrahim Jansen Khan Lund
    Mokoena Novak Okafor Petersen Quist Reyes Singh Thorne Usman Varga Walsh Xu Young Zulu
  ].freeze

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

  # A form whose every answer is unusable: the "n/a" era, an out-of-range value, a null.
  JUNK_ANSWERS = [nil, "n/a", 6, ""].freeze

  # A fixed roster per company, so re-seeding changes nothing.
  def employees(company)
    domain = "#{company.name.split.first.downcase}.example"

    FIRST_NAMES.each_with_index.map do |first, i|
      last = LAST_NAMES[i]
      company.employees.find_or_create_by!(email: "#{first}.#{last}@#{domain}".downcase) do |employee|
        employee.name = "#{first} #{last}"
      end
    end
  end

  # Rows for insert_all: `count` assessments spread over the six years before the anchor.
  def assessment_rows(company, count:, rng:, anchor: ANCHOR)
    employees = company.employees.order(:id).to_a

    Array.new(count) do
      employee = employees[rng.rand(employees.size)]
      created_at = anchor - rng.rand(0...(6 * 365)).days - rng.rand(0...86_400).seconds
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
  end

  private

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
    return QUESTIONS.to_h { |q| [q, JUNK_ANSWERS[rng.rand(JUNK_ANSWERS.size)]] } if rng.rand(100) < 2

    answers = QUESTIONS.to_h { |q| [q, answer(rng)] }.reject { |_, v| v == :missing }
    answers["comments"] = COMMENTS[rng.rand(COMMENTS.size)]
    answers
  end
end
