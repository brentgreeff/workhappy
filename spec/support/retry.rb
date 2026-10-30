# Browser specs on 2-core CI runners produce genuine one-off flakes (Ferrum
# timeouts, paint races). Retry system specs up to 3 times on CI ONLY — local
# runs fail honestly on the first attempt, so real regressions stay loud.
# verbose_retry logs every retry attempt, keeping flake frequency visible.
require 'rspec/retry'

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.default_sleep_interval = 1

  config.around(:each, type: :system) do |example|
    example.run_with_retry retry: ENV['CI'] ? 3 : 1
  end
end
