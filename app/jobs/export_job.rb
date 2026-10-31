require "csv"

# Builds one export's CSV in a worker and attaches it. Memory stays flat: rows are read in
# batches and written straight to a temp file.
class ExportJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(export) { export.company_id }

  HEADER = %w[id created_at status score].freeze

  def perform(export)
    export.processing!
    rows = 0

    Tempfile.create(["export-#{export.id}-", ".csv"]) do |file|
      csv = CSV.new(file)
      csv << HEADER
      export.assessments.select(:id, :created_at, :status).find_each(batch_size: 1_000) do |assessment|
        # Only derived or non-identifying columns leave the system. The score lands with
        # the dashboard work; until then the column is present and empty.
        csv << [assessment.id, assessment.created_at.iso8601, assessment.canonical_status, nil]
        rows += 1
      end
      csv.flush
      file.rewind
      export.file.attach(io: file, filename: export.filename, content_type: "text/csv", identify: false)
    end

    export.update!(status: :ready, row_count: rows)
  rescue StandardError => e
    export.update!(status: :failed, error_message: "Export failed. Please try again.")
    raise e
  end
end
