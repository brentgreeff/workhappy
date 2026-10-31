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

> Add minimal README setup instructions.

## 8. Assistant context

> Write a CLAUDE.md, gitignored, that says briefly what exists, what is still to do, and where the brief and the decisions live.

## 9. TypeScript

> Add TypeScript for the front end: jsbundling-rails with esbuild through npm, real .ts source, tsc strict with noEmit as the type check, importmap removed. tsc in the commit gate and in CI, npm audit in place of the importmap audit, and the spec jobs build the bundle before they run.

Why: the brief names TypeScript as a core technology and wants the export UI written in it. Rails 8 ships importmap, which serves JavaScript as-is with no compile step, so there was nowhere for a `.ts` file to go. The two honest options were a one-off tsc step feeding importmap, or jsbundling-rails with a bundler. I chose esbuild through npm: it is the standard Rails answer, one dependency, a build command and a watcher. esbuild strips types without checking them, so `tsc --noEmit` is the type check and runs in the commit gate and CI. Node becomes a requirement to run the app, which the README states.

## 10. Sign-in, companies, layout and theme

> Add sign-in with the Rails 8 authentication generator: email and password, no password reset. Add a Company model; a user belongs to a company, and the signed-in user's company is the tenant. Replace the ERB layout with Slim. Add flash partial and light/dark mode. Seeds with two companies and one admin each.

Why: Brief says a company admin may only see their own company and that access must never come from a client-supplied company id. That needs a session, which needs a sign-in. The Rails generator is the most basic version. Added `company_id` on users and `Current.company` as the one place the tenant comes from. The theme controller is TypeScript so the bundle has something real to type-check before the export UI arrives.
