require 'rails_helper'
require 'csv'

# The export runs as a job. spec/support/active_job.rb performs enqueued jobs inline in system
# specs, so by the time the page answers, the file exists and the UI shows the ready state.
RSpec.describe 'Assessments CSV export', type: :system do
  let(:company) { create(:company, name: 'Harbour Logistics') }
  let(:employee) { create(:employee, company:) }
  let(:user) { create(:user, company:) }

  # Fixed dates so the range boundaries are exact. a2 is the last second of 15 Feb and a3 the
  # first second of 16 Feb: an inclusive "to 15 Feb" keeps a2 and drops a3.
  let!(:a1) { assessment('2026-01-10 09:00', 'completed') }
  let!(:a2) { assessment('2026-02-15 23:59:59', 'complete') }
  let!(:a3) { assessment('2026-02-16 00:00:00', 'pending') }
  let!(:a4) { assessment('2026-03-01 12:00', 'done') }
  let!(:a5) { assessment('2026-04-01 12:00', 'cancelled') }

  before do
    other = create(:employee, company: create(:company, name: 'Meridian Legal'))
    create(:assessment, employee: other, status: 'completed', created_at: Time.zone.parse('2026-02-01 12:00'))
    sign_in user
  end

  # Rows as the old app left them: raw status, status_v2 NULL.
  def assessment(created_at, status)
    legacy_assessment(employee:, status:, created_at: Time.zone.parse(created_at))
  end

  # The export posts the dashboard's filter form as it stands, applied or not.
  def export(from: nil, to: nil, status: nil)
    fill_in 'From', with: from if from
    fill_in 'To', with: to if to
    select status, from: 'Status' if status
    click_button 'Export CSV'
  end

  def exported_ids
    expect(page).to have_css '.js-export-status', text: 'Ready'
    CSV.parse(Export.last.file.download, headers: true).map { |row| row['id'].to_i }
  end

  it 'exports every assessment of the admin company and none of the other company' do
    export

    expect(page).to have_css '.js-export-status', text: 'Ready: 5 rows'
    expect(exported_ids).to contain_exactly(a1.id, a2.id, a3.id, a4.id, a5.id)
  end

  it 'prefills the date range with the span of the company data' do
    expect(find_field('From').value).to eq '2026-01-10'
    expect(find_field('To').value).to eq '2026-04-01'
    export
    expect(exported_ids).to contain_exactly(a1.id, a2.id, a3.id, a4.id, a5.id)
  end

  it 'filters from a date, inclusive' do
    export(from: '2026-02-15')

    expect(exported_ids).to contain_exactly(a2.id, a3.id, a4.id, a5.id)
  end

  it 'filters to a date, inclusive of the whole day' do
    export(to: '2026-02-15')

    expect(exported_ids).to contain_exactly(a1.id, a2.id)
  end

  it 'filters a date range' do
    export(from: '2026-02-01', to: '2026-03-01')

    expect(exported_ids).to contain_exactly(a2.id, a3.id, a4.id)
  end

  it 'filters by canonical status, folding in the legacy spellings' do
    export(status: 'Completed')

    expect(exported_ids).to contain_exactly(a1.id, a2.id, a4.id)
  end

  it 'combines the status filter with a date range' do
    export(from: '2026-02-01', status: 'Completed')

    expect(exported_ids).to contain_exactly(a2.id, a4.id)
  end

  it 'rejects a reversed range and exports nothing' do
    export(from: '2026-03-01', to: '2026-02-01')

    expect(page).to have_css '.js-export-status', text: 'To must be on or after From'
    expect(Export.count).to eq 0
  end

  it 'leaves identifiers and free text out of the file' do
    a1.update_columns(employee_email: 'amara@harbour.example',
      responses_json: { 'posture' => 4, 'comments' => 'Call me on 07700 900123' })
    export

    csv = Export.last.file.download
    expect(csv.lines.first.chomp).to eq 'id,created_at,status,score'
    expect(csv).not_to include('amara', '07700', 'Call me')
  end
end
