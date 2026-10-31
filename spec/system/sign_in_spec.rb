require 'rails_helper'

RSpec.describe 'Sign in and out', type: :system do
  it 'signs in with email and password, then signs out and locks the app again' do
    user = create(:user)
    sign_in user

    expect(page).to have_content user.email_address

    find('.js-sign-out').click
    expect(page).to have_current_path(new_session_path)

    visit root_path
    expect(page).to have_current_path(new_session_path)
  end

  it 'bounces a wrong password back to the form' do
    user = create(:user)

    visit new_session_path
    fill_in 'Email address', with: user.email_address
    fill_in 'Password', with: 'wrong'
    click_button 'Sign in'

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_css '.js-flash-alert', text: 'Try another email address or password.'
  end
end
