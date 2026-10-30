source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "slim-rails"

gem "bcrypt", "~> 3.1.7"

# A bundled gem since Ruby 3.4: not loadable under Bundler unless declared.
gem "csv"

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  gem "dotenv"

  gem "pry-rails"
  gem "pry-doc"
  gem "pry-byebug"

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "simplecov", require: false


  gem "lefthook", require: false
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "capybara-email"
  gem "rspec-retry", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener"
  gem "hotwire-spark"
end
