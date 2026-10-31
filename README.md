# Workhappy

A small Rails slice around employee health assessments: a company-scoped CSV export, one measured dashboard improvement, and a status normalisation with a safe release plan. Design and trade-offs are in [SOLUTION.md](SOLUTION.md). AI assistance was used; the prompts and the reasoning behind them are in [PROMPTS.md](PROMPTS.md).

## Stack

Rails 8.1.4 · Ruby 3.4.10 (`.ruby-version`) · PostgreSQL 17 · Propshaft · TypeScript bundled by esbuild (Node, `.node-version`) · Tailwind (standalone binary) · Solid Queue/Cache/Cable on the one database.

## Run locally

You need Ruby with Bundler, Node with npm, and Docker for Postgres.

```sh
docker compose up -d   # Postgres 17 on localhost:5434, user/password: workhappy/password
bin/setup              # bundle install, npm install, db:prepare, then starts bin/dev
```

The app is on http://localhost:3002. On later runs, `bin/dev` alone starts the server, the esbuild watcher and the Tailwind watcher.

## Background jobs on localhost

Development uses Solid Queue, the same adapter as production, so an export on localhost is a real queued job. `bin/dev` starts the Solid Queue supervisor inside Puma: the `web` line of `Procfile.dev` sets `SOLID_QUEUE_IN_PUMA=1`, which turns on the plugin in `config/puma.rb`. No separate worker process is needed. The same line sets `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES`, which macOS needs before it will let the forked worker run ([solid_queue#407](https://github.com/rails/solid_queue/issues/407)); it does nothing on Linux.

To run the worker on its own instead, start the server without that variable and run `bin/jobs` in a second terminal. Queued, running and finished jobs are rows in the `solid_queue_*` tables on the one database.

## How to login on localhost

`bin/setup` seeds two companies with one admin each (`bin/rails db:seed` to re-run). Open http://localhost:3002 and sign in as either. Each admin only ever sees their own company.

| Company | Email | Password |
|---|---|---|
| Harbour Logistics | admin@harbour.example | password |
| Meridian Legal | admin@meridian.example | password |

## Try the export

Sign in, optionally set a From date, a To date (inclusive) and a Status, then click **Export CSV**. The status beside the button moves from Queued to Ready with the row count, and a **Download CSV** link appears. The file holds `id, created_at, status, score` only: no email, no answers, no free text. Status is the canonical value, so filtering on Completed also returns rows still stored as `complete`, `comp` or `done`.

The export is built by a Solid Queue job (see "Background jobs on localhost" above). Files are stored under `storage/` locally. Exports older than a day are purged hourly in production.

To check a downloaded file:

```sh
qsv validate ~/Downloads/assessments-1.csv   # RFC 4180 check (brew install qsv)
qsv stats ~/Downloads/assessments-1.csv      # column profile: types, ranges, nulls
```

To use your own Postgres instead of Docker, point `config/database.yml`'s `local` block at it.

## Data census

Two read-only rake tasks show what is in the assessments table. The status column holds years of free-text values and the answers JSON is inconsistently shaped; these tasks measure that, and [SOLUTION.md](SOLUTION.md) refers to their output.

```sh
bin/rails assessments:status_census      # every distinct status value with its count
bin/rails assessments:responses_census   # nil and empty responses_json, then per key: number, string, null, missing
```

Run the status census before and after the status backfill to prove the mapping. Both tasks are read-only but scan the whole table, and the second . On a large production table run them off-peak or against a follower, with a statement timeout set.

## Deploying to Heroku

`Procfile` runs one web dyno with the Solid Queue supervisor inside Puma, and `bin/rails db:migrate` as the release phase. Export files go to a bucket, because dynos do not share a disk and lose it on restart. Config vars: `RAILS_MASTER_KEY`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_BUCKET`, and optionally `AWS_REGION` (default `eu-west-2`). `DATABASE_URL` comes from the Postgres add-on. This wiring has not been exercised against a live app in this repository.

## Checks

```sh
bin/rspec                        # Specs; system specs - headless Chrome via Cuprite
npm run typecheck                # tsc over app/javascript
bin/ci                           # rubocop, tsc, brakeman, bundler-audit, npm audit, then the specs
bundle exec lefthook install     # optional: run the same gate as a pre-commit hook
```
