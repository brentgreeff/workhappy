require 'rails_helper'

RSpec.describe Employee do
  it 'normalises the email' do
    employee = create(:employee, email: '  Amara.Adeyemi@Harbour.example ')

    expect(employee.email).to eq 'amara.adeyemi@harbour.example'
  end

  it 'requires a name and an email' do
    employee = build(:employee, name: '', email: '')

    expect(employee).not_to be_valid
    expect(employee.errors[:name]).to be_present
    expect(employee.errors[:email]).to be_present
  end
end
