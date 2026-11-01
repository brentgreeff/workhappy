# Read-only counts over the assessments table, for the status backfill plan and the score
# diagnosis. Pure data out; the rake tasks do the printing.
module AssessmentCensus
  extend self

  # { status => count }, most common first. nil and "" stay distinct keys.
  def statuses(scope = Assessment.all)
    scope.group(:status).count.sort_by { |status, n| [-n, status.to_s] }.to_h
  end

  # The same for the new column: only the five values and nil can appear.
  def statuses_v2(scope = Assessment.all)
    scope.group(:status_v2).count.sort_by { |status, n| [-n, status.to_s] }.to_h
  end

  # Shapes of responses_json across the scope. Arrays, strings, numbers and JSON null are
  # counted together as non_object.
  def responses(scope = Assessment.all)
    objects = scope.with_response_object
    empty_object = objects.with_empty_responses.count
    with_answers = objects.count - empty_object

    {
      total: scope.count,
      nil_json: scope.where(responses_json: nil).count,
      non_object: scope.with_non_object_responses.count,
      empty_object:,
      with_answers:,
      keys: key_shapes(objects, with_answers:)
    }
  end

  private

  # { "posture" => { "number" => 444, "string" => 59, "null" => 42, "missing" => 20 }, ... }
  # "missing" is relative to the rows that have at least one answer.
  def key_shapes(objects, with_answers:)
    counts = objects.joins_each_response.grouped_by_response_key_and_type.count

    shapes = Hash.new { |h, k| h[k] = {} }
    counts.each { |(key, type), n| shapes[key][type] = n }
    shapes.each_value { |types| types["missing"] = with_answers - types.values.sum }
    shapes.sort.to_h
  end
end
