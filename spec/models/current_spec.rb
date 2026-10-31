require 'rails_helper'

RSpec.describe Current do
  it 'resolves the tenant through the signed-in user' do
    user = create(:user)

    Current.set(session: user.sessions.create!) do
      expect(Current.company).to eq user.company
    end
  end

  # A nil tenant would turn a scope into `company_id IS NULL`. Nobody signed in must raise.
  it 'raises when nobody is signed in' do
    expect { Current.company }.to raise_error(ActiveSupport::DelegationError)
  end
end
