namespace :assessments do
  desc "Count every distinct status value. Read-only, one grouped query over the whole table."
  task status_census: :environment do
    counts = AssessmentCensus.statuses
    width = [*counts.keys.map { |status| status.inspect.length }, "total".length].max

    counts.each { |status, n| puts "#{status.inspect.ljust(width)}  #{n}" }
    puts "#{'total'.ljust(width)}  #{counts.values.sum}"
  end

  desc "Count the shapes of responses_json: nil, non-object, empty, and per key how many " \
    "answers are numbers, strings, nulls or missing. Read-only, expands every JSON value."
  task responses_census: :environment do
    census = AssessmentCensus.responses
    summary = census.except(:keys).map { |label, n| "#{label.to_s.tr('_', ' ')} #{n}" }
    puts summary.join(", ")

    census[:keys].each do |key, types|
      puts "#{key.ljust(10)} #{types.map { |type, n| "#{type} #{n}" }.join(', ')}"
    end
  end
end
