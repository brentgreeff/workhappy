require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  it 'lands the signed-in admin on their own company dashboard' do
    user = create(:user, company_name: 'Harbour Logistics')
    sign_in user

    expect(page).to have_css '.js-company', text: 'Harbour Logistics'
    expect(page).to have_css '.js-main-nav [aria-current="page"]', text: 'Assessments'
  end
end
