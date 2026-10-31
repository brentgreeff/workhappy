require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'signed out' do
    it 'redirects every app page to the sign-in form' do
      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    # The sign-in page renders layouts/authentication, which is what lets the main layout
    # use Current.user with no nil check. If it ever renders the main layout again, that
    # assumption breaks quietly, so pin it here.
    it 'renders the sign-in form with the theme menu but no sign out' do
      get new_session_path

      expect(response).to have_http_status :ok
      expect(response.body).to include 'js-theme-menu'
      expect(response.body).not_to include 'js-sign-out'
    end
  end

  describe 'signed in' do
    it 'serves the app page for the session cookie' do
      sign_in_as create(:user)

      get root_path

      expect(response).to have_http_status :ok
      expect(response.body).to include 'js-sign-out'
    end
  end
end
