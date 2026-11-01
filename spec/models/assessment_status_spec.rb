require 'rails_helper'
require Rails.root.join('db/migrate/20261101131128_add_status_v2_to_assessments')

RSpec.describe AssessmentStatus do
  RAW_VALUES = ['completed', 'Complete ', 'COMP', 'done', 'pending', 'in_progress', 'needs_follow_up',
    'archived', 'n/a', '', nil, 'cancelled', ' Pending'].freeze

  it 'has the same five values as the database constraint' do
    expect(AddStatusV2ToAssessments::ALLOWED).to eq described_class::CANONICAL
  end

  it 'treats the unmapped predicate as the complement of the known spellings' do
    employee = create(:employee)
    RAW_VALUES.each { |raw| legacy_assessment(employee:, status: raw) }

    unmapped = Assessment.where(described_class.unmapped_arel).pluck(:status)
    expect(unmapped).to contain_exactly('n/a', '', nil, 'cancelled')
  end
end
