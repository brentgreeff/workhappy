namespace :assessments do
  desc "Count every distinct status value. Read-only, one grouped query; safe to run live."
  task status_census: :environment do
    counts = Assessment.group(:status).count.sort_by { |status, n| [-n, status.to_s] }
    width = counts.map { |status, _| status.inspect.length }.max

    counts.each { |status, n| puts "#{status.inspect.ljust(width)}  #{n}" }
    puts "#{'total'.ljust(width)}  #{counts.sum { |_, n| n }}"
  end

  desc "Count the shapes of responses_json: nil, empty, and per key how many answers are " \
    "numbers, strings, nulls or missing. Read-only."
  task responses_census: :environment do
    total = Assessment.count
    nil_json = Assessment.where(responses_json: nil).count
    empty = Assessment.where("responses_json = '{}'::jsonb").count
    with_answers = total - nil_json - empty
    puts "total #{total}, nil json #{nil_json}, empty object #{empty}, with answers #{with_answers}"

    rows = Assessment.connection.select_rows(<<~SQL)
      SELECT key, jsonb_typeof(value), count(*)
      FROM assessments, jsonb_each(responses_json)
      GROUP BY key, jsonb_typeof(value)
      ORDER BY key, 2
    SQL

    rows.group_by(&:first).each do |key, by_type|
      present = by_type.sum { |_, _, n| n }
      types = by_type.map { |_, type, n| "#{type} #{n}" }.join(", ")
      puts "#{key.ljust(10)} #{types}, missing #{with_answers - present}"
    end
  end
end
