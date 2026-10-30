require 'capybara/cuprite'

# NOT named :cuprite — Rails 8 driven_by re-registers names it knows (selenium,
# cuprite, rack_test, playwright) with its own defaults, clobbering this config.
# An unknown name makes driven_by use this registration untouched.
Capybara.register_driver :cuprite_custom do |app|
  Capybara::Cuprite::Driver.new(
    app,
    js_errors: true,
    window_size: [1400, 900],
    inspector: true,
    # CI (ubuntu) restricts unprivileged user namespaces via AppArmor, so Chrome's
    # sandbox can't initialize and Ferrum raises ProcessTimeoutError at launch.
    # Sandboxless is the standard CI setting; the longer process_timeout covers
    # slow 2-core runners. Locally 20s (not Ferrum's 10s default) — batch Guard runs
    # boot several Chromes back-to-back and cold boots under load blow 10s.
    browser_options: ENV['CI'] ? { 'no-sandbox' => nil } : {},
    process_timeout: ENV['CI'] ? 30 : 20,
    # Abort external font requests up front — they hang in the test env and
    # destabilise the page. Regexps, not glob strings (ferrum >= 0.17).
    url_blacklist: [/fonts\.googleapis\.com/, /fonts\.gstatic\.com/]
  )
end

# 2-core CI runners render/execute JS several times slower than a dev Mac.
Capybara.default_max_wait_time = ENV['CI'] ? 15 : 5

# CI pipes rspec's stdout, so Ruby block-buffers it and progress dots never flush.
$stdout.sync = true

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  elsif ENV['NO_COVERAGE'].nil? && File.basename($0) == 'rspec'
    # Coverage on full-suite runs only — skipped for single-file runs (TDD
    # loop) and when NO_COVERAGE is set (CI sets it — branch tracking adds 15-25%
    # Ruby time and nothing consumes the report there). Report: coverage/index.html.
    # The $0 check: rspec-rails generators boot this file via .rspec's
    # --require spec_helper ($0 = bin/rails), which used to emit a bogus 0% report
    # after every `rails generate` with an rspec hook.
    require 'simplecov'
    SimpleCov.start do
      cover '{app,lib}/**/*.rb'
      enable_coverage :branch
      group 'Controllers', 'app/controllers'
      group 'Models',      'app/models'
      group 'Jobs',        'app/jobs'
    end
  end
end
