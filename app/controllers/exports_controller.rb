class ExportsController < ApplicationController
  before_action :no_store

  def create
    export = Current.company.exports.new(export_params.merge(user: Current.user))

    if export.save
      ExportJob.perform_later(export)
      render json: payload(export), status: :accepted
    else
      render json: { error: export.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def show
    render json: payload(find_export)
  end

  def download
    export = find_export
    return head :conflict unless export.ready? && export.file.attached?

    send_data export.file.download, filename: export.filename, type: "text/csv", disposition: "attachment"
  end

  private

  # Through the tenant, never by bare id: another company's export is a 404.
  def find_export
    Current.company.exports.find(params[:id])
  end

  def export_params
    params.require(:export).permit(:from_date, :to_date, :status_filter)
  end

  def payload(export)
    {
      id: export.id,
      status: export.status,
      row_count: export.row_count,
      error: export.error_message,
      poll_url: export_path(export),
      download_url: (download_export_path(export) if export.ready?)
    }
  end

  def no_store
    response.headers["Cache-Control"] = "private, no-store"
  end
end
