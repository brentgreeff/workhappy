require 'rails_helper'

RSpec.describe Assessment do
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
