class ExportsController < ApplicationController
  before_action :no_store

  # Posted by the dashboard's filter form, so the file holds exactly what the form says.
  def create
    export = Current.user.exports.new(export_params)

    if export.save
      ExportJob.perform_later(export)
      render json: ExportPayload.for(export:), status: :accepted
    else
      render json: { error: export.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def show
    render json: ExportPayload.for(export: find_export)
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

  # The form posts the filter's own field names; on an export, status is the export's state.
  def export_params
    filter = params.expect(filter: [:from_date, :to_date, :status])
    { from_date: filter[:from_date], to_date: filter[:to_date], status_filter: filter[:status] }
  end

  def no_store
    response.headers["Cache-Control"] = "private, no-store"
  end
end
