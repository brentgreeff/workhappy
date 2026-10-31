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
