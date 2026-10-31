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

## 11. Employees

> Run the model generator for Employee: company, name, email. Seed a fixed roster per company in its own seed file, called from the primary seed file.

Why: Brief lists employees as an entity assessments belong to, and asks for no UI for them. A table and seeds are enough. Fixed roster so re-seeding is a no-op and the assessments seed can reuse the same people.

## 12. Assessments

> Run the model generator for an Assessment with the fields: company, employee, employee_email, status as a plain string, responses_json as jsonb. No status validation and no score yet. Seed a few hundred per company over several years in its own seed file: statuses from the brief's list including empty string and nil, answers 1 to 5 with the legacy mess mixed in (strings, nulls, missing keys, empty objects), one free-text field.

Why: This is the "before". Task 2 fixes the score and Task 3 constrains the status, so neither exists yet and the commit history shows the change. Only the indexes the references give: the dashboard index is Task 2's measurment. `employee_email` stays on the row because the brief describes it and Task 1 redacts it. Seed should be the same on every machine.

## 13. Census tasks

> Write 2 rake tasks to audot the seed data: one counting `every distinct status value`, another  `counting the shapes of responses_json` (nil, empty, and per key - how many answers by type, nulls or missing). Read-only.

Why: The status census is step one of Task 3's release plan: run it on production before writing the mapping, and again after the backfill to prove it. The responses census quantifies why the score goes blank, which is where Task 2 starts. Rake because they need the app loaded and `bin/rails task` - to run on Heroku.

## 14. Tenant integrity between assessments and employees

> An assessment has two independent foreign keys, so it can point at another company's employee. Enforce same-company at the database with a composite foreign key, add the model validation for a readable error, and a spec that builds the mismatch.

Why: Scoping every query by `company_id` does not stop a row that carries another tenant's employee and email. A composite foreign key on `(employee_id, company_id)` makes that row impossible, including through `insert_all` and the console, which a validation never sees.
