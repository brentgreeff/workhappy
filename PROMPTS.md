# PROMPTS.md

## 1. Scaffold

> Create a new Rails app for this take-home. Latest stable Rails, Ruby 3.4 in its own rvm gemset. Postgres. Propshaft and importmap, Tailwind through the standalone binary, Slim templates, Hotwire. No minitest, jbuilder, Action Mailbox, Action Text. Also skip Docker, Kamal and Thruster.

## 2. Gemfile, local infrastructure, one database

> Gemfile: add bcrypt, csv, and the dev/test stack: rspec-rails, factory_bot_rails, capybara, cuprite, rspec-retry, simplecov, pry, dotenv, lefthook. letter_opener and hotwire-spark in development. No image_processing.
>
> docker-compose with Postgres 17 on a port no other project on my machine uses. database.yml with one local anchor shared by development and test. Put the web server on a free port.
>
> Add Solid Queue, Solid Cache and Solid Cable on the single primary database, the way a Heroku app would: one migration for all their tables, production configured primary-only.

## 4. Commit gate

> Add lefthook. Pre-commit: rubocop on the staged Ruby files, brakeman, bundler-audit and importmap audit, in parallel. It should mirror what CI runs.

## 6. RSpec and CI

> Set up RSpec with Cuprite: register the driver, no-sandbox Chrome. longer timeouts on CI, factory_bot, retries on CI only, screenshots and page HTML saved for system-spec failure, SimpleCov on full-suite runs only. Write a system spec that asserts the homepage.
>
> CI on GitHub Actions: rubocop, brakeman with bundler-audit, importmap audit, request specs & system specs as separate jobs witb Postgres.

## 7. README

> Add minimal README setup instructions. Plain commands only.

## 8. Assistant context

> Write a CLAUDE.md, gitignored, that says briefly what exists, what is still to do, and where the brief and the decisions live.

## 9. TypeScript

> Add TypeScript for the front end: jsbundling-rails with esbuild through npm, real .ts source, tsc strict with noEmit as the type check, importmap removed. tsc in the commit gate and in CI, npm audit in place of the importmap audit, and the spec jobs build the bundle before they run.
