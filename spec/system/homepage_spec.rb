require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  it 'shows the signed-in admin their own company' do
    user = create(:user, company_name: 'Harbour Logistics')
    sign_in user

    expect(page).to have_css 'h1', text: 'Harbour Logistics'
  end
end
