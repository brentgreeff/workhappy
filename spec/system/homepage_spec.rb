require 'rails_helper'

RSpec.describe 'Homepage', type: :system do
  it 'renders' do
    visit root_path

    expect(page).to have_css 'h1', text: 'Workhappy'
  end
end
