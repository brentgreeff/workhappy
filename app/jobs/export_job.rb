require "csv"

# Builds one export's CSV in a worker and attaches it. Memory stays flat: rows are read in
# batches and written straight to a temp file.
class ExportJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(export) { export.company_id }

HEADER = %w[id created_at status score].freeze

# What a failed export re-raises. The original message can carry row data (an answer, an
# email) and both the failed-jobs table and the job log store the message verbatim, so only
# the class name travels; the original backtrace is kept, and the original is the cause.
class Failed < StandardError; end

  def perform(export)
    export.processing!
    rows = 0

    Tempfile.create(["export-#{export.id}-", ".csv"]) do |file|
      csv = CSV.new(file)
      csv << HEADER
      # responses_json is read to compute the score and never written out.
      export.assessments.select(:id, :created_at, :status, :responses_json).find_each(batch_size: 1_000) do |assessment|
        csv << [assessment.id, assessment.created_at.iso8601, assessment.canonical_status, assessment.score]
        rows += 1
      end
      csv.flush
      file.rewind
      export.file.attach(io: file, filename: export.filename, content_type: "text/csv", identify: false)
    end

    export.update!(status: :ready, row_count: rows)
  rescue StandardError => e
    export.update!(status: :failed, error_message: "Export failed. Please try again.")
    raise Failed, e.class.name, e.backtrace
  end
end
