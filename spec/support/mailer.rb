# rspec-rails does not clear deliveries between examples (Rails' own test
# framework does) — stale mail from a previous example can satisfy open_email.
RSpec.configure do |config|
  config.before(:each) { ActionMailer::Base.deliveries.clear }
end
