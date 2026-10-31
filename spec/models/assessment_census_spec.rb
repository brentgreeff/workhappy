require 'rails_helper'

RSpec.describe AssessmentCensus do
  let(:employee) { create(:employee) }

  def assessment(**attrs)
    create(:assessment, employee:, **attrs)
  end

  describe '.statuses' do
    it 'counts every distinct value, most common first, keeping nil and blank apart' do
      assessment(status: 'completed')
      assessment(status: 'completed')
      assessment(status: 'comp')
      assessment(status: nil)
      assessment(status: '')

      expect(described_class.statuses).to eq(
        'completed' => 2, '' => 1, 'comp' => 1, nil => 1
      )
    end

    it 'is empty for an empty table' do
      expect(described_class.statuses).to eq({})
    end
  end

  describe '.responses' do
    it 'separates nil, non-object and empty JSON from rows with answers, then counts each key by type' do
      assessment(responses_json: nil)
      assessment(responses_json: [1, 2])
      assessment(responses_json: {})
      assessment(responses_json: { 'posture' => 4, 'screen' => '3' })
      assessment(responses_json: { 'posture' => nil })

      census = described_class.responses

      expect(census.except(:keys)).to eq(
        total: 5, nil_json: 1, non_object: 1, empty_object: 1, with_answers: 2
      )
      expect(census[:keys]).to eq(
        'posture' => { 'number' => 1, 'null' => 1, 'missing' => 0 },
        'screen' => { 'string' => 1, 'missing' => 1 }
      )
    end

    it 'is all zeros for an empty table' do
      expect(described_class.responses).to eq(
        total: 0, nil_json: 0, non_object: 0, empty_object: 0, with_answers: 0, keys: {}
      )
    end
  end
end
