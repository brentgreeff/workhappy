require 'rails_helper'

RSpec.describe 'Assessments dashboard', type: :system do
  let(:company) { create(:company, name: 'Harbour Logistics') }
  let(:amara) { create(:employee, company:, name: 'Amara Adeyemi') }
  let(:ben) { create(:employee, company:, name: 'Ben Brooks') }
  let(:user) { create(:user, company:) }

  before do
    other = create(:employee, company: create(:company), name: 'Zara Zulu')
    create(:assessment, employee: other, status: 'completed', created_at: Time.zone.parse('2026-02-01 12:00'))
    sign_in user
  end

  def assessment(employee, created_at, status)
    create(:assessment, employee:, status:, created_at: Time.zone.parse(created_at))
  end

  def rows
    all('.js-assessment-row').map(&:text)
  end

  def filter(from: nil, to: nil, status: nil)
    fill_in 'From', with: from if from
    fill_in 'To', with: to if to
    select status, from: 'Status' if status
    click_button 'Filter'
  end

  context 'with a handful of assessments' do
    before do
      assessment(amara, '2026-01-10 09:00', 'completed')
      assessment(ben, '2026-02-15 23:59:59', 'complete')
      assessment(amara, '2026-02-16 00:00:00', 'pending')
      assessment(ben, '2026-03-01 12:00', 'done')
      assessment(amara, '2026-04-01 12:00', 'cancelled')
      visit root_path
    end

    it 'lists the company assessments newest first and never the other company' do
      expect(rows.size).to eq 5
      expect(rows.first).to include('Amara Adeyemi', '1 Apr 2026', 'Unmapped')
      expect(rows.last).to include('Amara Adeyemi', '10 Jan 2026', 'Completed')
      expect(page).not_to have_content 'Zara Zulu'
    end

    it 'filters by date range, end date inclusive' do
      filter(from: '2026-02-01', to: '2026-02-15')

      expect(rows.size).to eq 1
      expect(rows.first).to include('Ben Brooks', '15 Feb 2026')
    end

    it 'filters by canonical status, folding in the legacy spellings' do
      filter(status: 'Completed')

      expect(rows.size).to eq 3
      expect(rows).to all(include('Completed'))
    end

    it 'combines both filters and keeps them in the form' do
      filter(from: '2026-02-01', status: 'Completed')

      expect(rows.size).to eq 2
      expect(find_field('From').value).to eq '2026-02-01'
      expect(find_field('Status').value).to eq 'completed'
    end

    it 'rejects a reversed range and lists nothing' do
      filter(from: '2026-03-01', to: '2026-02-01')

      expect(page).to have_css '.js-flash-alert', text: 'To must be on or after From'
      expect(rows).to be_empty
    end

    it 'exports the rows currently filtered' do
      filter(status: 'Completed')
      click_button 'Export CSV'

      expect(page).to have_css '.js-export-status', text: 'Ready: 3 rows'
    end
  end

  context 'with more than a page' do
    before do
      start = Time.zone.parse('2026-01-01 00:00')
      55.times { |i| create(:assessment, employee: amara, status: 'pending', created_at: start + i.hours) }
      visit root_path
    end

    it 'shows 50 per page with the page count and links to the rest' do
      expect(rows.size).to eq 50
      expect(page).to have_css '.js-pagination', text: 'Page 1 of 2'

      click_link 'Next'
      expect(rows.size).to eq 5
      expect(page).to have_css '.js-pagination', text: 'Page 2 of 2'
      expect(page).not_to have_link 'Next'

      click_link 'Previous'
      expect(rows.size).to eq 50
    end

    it 'clamps a page past the end to the last page' do
      visit root_path(page: 9)

      expect(rows.size).to eq 5
      expect(page).to have_css '.js-pagination', text: 'Page 2 of 2'
    end
  end
end
