require 'rails_helper'

RSpec.describe User do
  it 'rejects a second account on the same address, whatever the case or spacing' do
    create(:user, email_address: 'admin@harbour.example')
    duplicate = build(:user, email_address: '  Admin@Harbour.example ')

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email_address]).to be_present
  end
end
