# How an assessment's answers become one number. The table is the whole rule: points per
# answer, per question, 5 meaning "no concern" on every question today. A question scored the
# other way round, or weighted, is a change to this table, not to the code.
module AssessmentScoring
  extend self

  POINTS = {
    "posture" => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 },
    "screen" => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 },
    "chair" => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 },
    "breaks" => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 },
    "lighting" => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 }
  }.freeze

  MIN_ANSWERS = 3

  # Mean of the mapped points over the questions with a mappable answer, rounded; nil when
  # fewer than MIN_ANSWERS map. Garbage never becomes a number: an answer counts only when it
  # is an integer, or a string of digits, that is a key in its question's table.
  def score(responses)
    points = mapped_points(responses)
    return nil if points.size < MIN_ANSWERS

    (points.sum.to_f / points.size).round
  end

  # Why there is no score, or nil when there is one. Tells an admin whether to chase the
  # employee (no answers), the data (invalid answers) or neither yet (insufficient).
  def reason(responses)
    mapped = mapped_points(responses).size
    return nil if mapped >= MIN_ANSWERS

    answered = responses.is_a?(Hash) ? POINTS.keys.count { |question| responses.key?(question) } : 0
    return :no_answers if answered.zero?
    return :invalid_answers if mapped.zero?

    :insufficient_answers
  end

  private

  def mapped_points(responses)
    return [] unless responses.is_a?(Hash)

    POINTS.filter_map { |question, table| table[answer_key(responses[question])] }
  end

  def answer_key(value)
    case value
    when Integer then value
    when /\A\d+\z/ then value.to_i
    end
  end
end
