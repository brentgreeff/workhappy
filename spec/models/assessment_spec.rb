require 'rails_helper'

RSpec.describe Assessment do
  describe 'tenant integrity' do
    # The factory always builds a consistent pair, so the mismatch has to be made by hand.
    it 'rejects an employee from another company' do
      assessment = build(:assessment, company: create(:company), employee: create(:employee))

      expect(assessment).not_to be_valid
      expect(assessment.errors[:employee]).to be_present
    end

    it 'is enforced by the database as well, past the validation' do
      assessment = build(:assessment, company: create(:company), employee: create(:employee))

      expect { assessment.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe 'status going forward' do
    let(:employee) { create(:employee) }

    it 'derives the canonical status_v2 from whatever was written, keeping the raw value' do
      assessment = create(:assessment, employee:, status: 'Comp ')

      expect(assessment.status).to eq 'Comp '
      expect(assessment.status_v2).to eq 'completed'
      expect(assessment.canonical_status).to eq 'completed'
    end

    it 'refuses a new record whose status maps to nothing, naming the value' do
      assessment = build(:assessment, employee:, status: 'cancelled')

      expect(assessment).not_to be_valid
      expect(assessment.errors[:status].first).to start_with '"cancelled" is not one of pending'
    end

    it 'refuses changing an existing status to something that maps to nothing' do
      assessment = create(:assessment, employee:)

      expect(assessment.update(status: 'n/a')).to be false
      expect(assessment.reload.status_v2).to eq 'completed'
    end

    it 'allows an unrelated edit to a legacy row whose value maps to nothing, leaving it unmapped' do
      legacy = legacy_assessment(employee:, status: 'cancelled')

      expect(legacy.update(employee_email: 'moved@example.com')).to be true
      expect(legacy.reload.status_v2).to be_nil
      expect(legacy.canonical_status).to eq 'unmapped'
    end

    it 'does not recompute status_v2 on an unrelated edit, so a backfilled value survives' do
      legacy = legacy_assessment(employee:, status: 'n/a')
      legacy.update_columns(status_v2: 'archived')   # resolved by the backfill or triage

      legacy.update!(employee_email: 'moved@example.com')

      expect(legacy.reload.status_v2).to eq 'archived'
    end

    it 'is refused by the database as well, past the model' do
      assessment = create(:assessment, employee:)

      expect { assessment.update_columns(status_v2: 'bogus') }.to raise_error(ActiveRecord::StatementInvalid, /assessments_status_v2_allowed/)
    end

    it 'finds a row by canonical status through either column' do
      filled = create(:assessment, employee:, status: 'done')
      legacy = legacy_assessment(employee:, status: 'Complete')
      legacy_assessment(employee:, status: 'pending')

      expect(Assessment.with_status('completed')).to contain_exactly(filled, legacy)
      expect(Assessment.unmapped).to be_empty
    end

    it 'lists the rows nothing maps as unmapped' do
      create(:assessment, employee:)
      stray = legacy_assessment(employee:, status: 'cancelled')
      blank = legacy_assessment(employee:, status: '')

      expect(Assessment.unmapped).to contain_exactly(stray, blank)
    end
  end

  describe 'responses_json shape scopes' do
    let(:employee) { create(:employee) }
    let!(:answered) { create(:assessment, employee:, responses_json: { 'posture' => 4 }) }
    let!(:empty) { create(:assessment, employee:, responses_json: {}) }

    let!(:array) { create(:assessment, employee:, responses_json: [1, 2]) }
    let!(:string) { create(:assessment, employee:, responses_json: 'text') }

    before { create(:assessment, employee:, responses_json: nil) }

    it '.with_response_object keeps objects only, empty ones included' do
      expect(described_class.with_response_object).to contain_exactly(answered, empty)
    end

    it '.with_non_object_responses keeps JSON that is present but not an object' do
      expect(described_class.with_non_object_responses).to contain_exactly(array, string)
    end

    it '.with_empty_responses keeps the empty object only' do
      expect(described_class.with_empty_responses).to contain_exactly(empty)
    end
  end
end
