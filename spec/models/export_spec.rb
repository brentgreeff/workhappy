require 'rails_helper'

RSpec.describe Export do
  let(:user) { create(:user) }

  it 'takes its company from the user who asked for it' do
    expect(user.exports.create!.company).to eq user.company
  end
end
