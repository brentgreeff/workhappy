require 'rails_helper'

RSpec.describe AssessmentFilter do
  it 'accepts blank filters' do
    expect(described_class.new).to be_valid
  end

  # The date type casts garbage to nil; left alone that would silently export everything.
  it 'rejects a date that does not parse instead of widening the query' do
    filter = described_class.new(from_date: 'last tuesday')

    expect(filter).not_to be_valid
    expect(filter.errors.full_messages).to eq ['From is not a date']
  end

  it 'rejects a reversed range' do
    filter = described_class.new(from_date: '2026-03-01', to_date: '2026-02-01')

    expect(filter.errors.full_messages).to be_empty
    expect(filter).not_to be_valid
    expect(filter.errors.full_messages).to eq ['To must be on or after From']
  end

  it 'rejects a status that is not canonical, legacy spellings included' do
    expect(described_class.new(status: 'done')).not_to be_valid
    expect(described_class.new(status: 'completed')).to be_valid
  end
end
