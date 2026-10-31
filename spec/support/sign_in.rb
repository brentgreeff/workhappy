module SignInHelper
  def sign_in(user, password: 'password')
    visit new_session_path
    fill_in 'Email address', with: user.email_address
    fill_in 'Password', with: password
    click_button 'Sign in'
    expect(page).to have_current_path(root_path)
  end
end

RSpec.configure do |config|
  config.include SignInHelper, type: :system
end
