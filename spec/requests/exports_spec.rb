require 'rails_helper'
require 'csv'

RSpec.describe 'Exports', type: :request do
  let(:user) { create(:user) }

  before { sign_in_as user }

  describe 'POST /exports' do
    it 'creates the export for the admin company only, whatever the body says' do
      other = create(:company)

      post exports_path, params: { filter: { status: 'completed', company_id: other.id } }, as: :json

      expect(response).to have_http_status :accepted
      expect(Export.last.company).to eq user.company
      expect(response.parsed_body).to include('status' => 'queued', 'download_url' => nil)
    end

    it 'is a bad request without the filter fields' do
      post exports_path, params: {}, as: :json

      expect(response).to have_http_status :bad_request
      expect(Export.count).to eq 0
    end

    it 'rejects an unknown status' do
      post exports_path, params: { filter: { status: 'done' } }, as: :json

      expect(response).to have_http_status :unprocessable_entity
      expect(Export.count).to eq 0
    end
  end

  describe "another company's export" do
    let(:foreign) { create(:export) }

    it 'is not found when polled' do
      get export_path(foreign), as: :json

      expect(response).to have_http_status :not_found
    end

    it 'is not found when downloaded' do
      get download_export_path(foreign)

      expect(response).to have_http_status :not_found
    end
  end

  describe 'GET /exports/:id/download' do
    it 'refuses until the file is ready' do
      export = create(:export, user:)

      get download_export_path(export)

      expect(response).to have_http_status :conflict
    end

    it 'serves the file as an attachment with no caching' do
      export = create(:export, user:)
      perform_enqueued_jobs { ExportJob.perform_later(export) }

      get download_export_path(export)

      expect(response).to have_http_status :ok
      expect(response.headers['Content-Disposition']).to include('attachment', export.filename)
      expect(response.headers['Cache-Control']).to include 'no-store'
      expect(response.body.lines.first.chomp).to eq 'id,created_at,status,score'
    end

    it 'carries the same score the dashboard shows, blank when there is none' do
      scored = create(:assessment, employee: create(:employee, company: user.company))
      thin = create(:assessment, employee: scored.employee, responses_json: { 'posture' => 4 })
      export = create(:export, user:)
      perform_enqueued_jobs { ExportJob.perform_later(export) }

      get download_export_path(export)

      rows = CSV.parse(response.body, headers: true).to_h { |row| [row['id'].to_i, row['score']] }
      expect(rows[scored.id]).to eq '65'
      expect(rows[thin.id]).to be_nil
    end
  end
end
