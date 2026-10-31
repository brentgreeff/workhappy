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

## How to login on localhost

`bin/setup` seeds two companies with one admin each (`bin/rails db:seed` to re-run). Open http://localhost:3002 and sign in as either. Each admin only ever sees their own company.

| Company | Email | Password |
|---|---|---|
| Harbour Logistics | admin@harbour.example | password |
| Meridian Legal | admin@meridian.example | password |

To use your own Postgres instead of Docker, point `config/database.yml`'s `local` block at it.

## Checks

```sh
bin/rspec                        # Specs; system specs - headless Chrome via Cuprite
npm run typecheck                # tsc over app/javascript
bin/ci                           # rubocop, tsc, brakeman, bundler-audit, npm audit, then the specs
bundle exec lefthook install     # optional: run the same gate as a pre-commit hook
```
