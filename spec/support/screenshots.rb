# On system-spec failure, capture the browser's final state (PNG + HTML) into
# tmp/capybara/. CI uploads that dir as an artifact, giving post-mortem pixels
# for failures we can't reproduce locally.
RSpec.configure do |config|
  config.after(:each, type: :system) do |example|
    next unless example.exception
    next unless Capybara.current_session.server # browser never started — nothing to capture

    name = example.full_description.gsub(/[^a-z0-9]+/i, '_').downcase[0, 80]
    dir  = Rails.root.join('tmp/capybara')
    FileUtils.mkdir_p(dir)
    page.save_screenshot(dir.join("#{name}.png").to_s, full: true)
    page.save_page(dir.join("#{name}.html").to_s)
  rescue StandardError => e
    warn "screenshot capture failed (#{example.location}): #{e.class}: #{e.message}"
  end
end
