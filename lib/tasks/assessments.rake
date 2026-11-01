namespace :assessments do
  desc "Count every distinct status value, split into known and unresolved spellings, and the " \
    "status_v2 distribution. Read-only; one grouped query over the whole table."
  task status_census: :environment do
    counts = AssessmentCensus.statuses
    width = [*counts.keys.map { |status| status.inspect.length }, "total".length].max

    counts.each do |status, n|
      marker = AssessmentStatus.normalize(status) ? "" : "  <- unresolved"
      puts "#{status.inspect.ljust(width)}  #{n}#{marker}"
    end
    puts "#{'total'.ljust(width)}  #{counts.values.sum}"

    puts "\nstatus_v2:"
    AssessmentCensus.statuses_v2.each { |status, n| puts "#{status.inspect.ljust(width)}  #{n}" }
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
