require 'rails_helper'

RSpec.describe 'Theme selector', type: :system do
  before { sign_in create(:user) }

  it 'auto-detects the OS preference and follows live changes when no choice is stored' do
    emulate_color_scheme 'light'
    visit root_path

    expect(page).to have_css 'html:not(.dark)'

    find('.js-theme-menu').hover
    expect(page).to have_css 'button[aria-checked="true"]', text: 'System'

    emulate_color_scheme 'dark'
    expect(page).to have_css 'html.dark'
  end

  it 'persists an explicit choice and returns to auto-detect via System' do
    emulate_color_scheme 'light'
    visit root_path

    find('.js-theme-menu').hover
    click_button 'Dark'
    expect(page).to have_css 'html.dark'

    visit root_path
    expect(page).to have_css 'html.dark'

    find('.js-theme-menu').hover
    expect(page).to have_css 'button[aria-checked="true"]', text: 'Dark'

    click_button 'System'
    expect(page).to have_css 'html:not(.dark)'
  end

  def emulate_color_scheme(value)
    page.driver.browser.page.command(
      'Emulation.setEmulatedMedia',
      features: [{ name: 'prefers-color-scheme', value: }]
    )
  end
end
