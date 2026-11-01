# What the export controller's TypeScript polls: state, row count, the failure message, and
# where to poll and download next.
module ExportPayload
  extend self

  def for(export:)
    routes = Rails.application.routes.url_helpers
    {
      id: export.id,
      status: export.status,
      row_count: export.row_count,
      error: export.error_message,
      poll_url: routes.export_path(export),
      download_url: (routes.download_export_path(export) if export.ready?)
    }
  end
end
