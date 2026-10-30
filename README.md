# Workhappy

A small Rails slice around employee health assessments: a company-scoped CSV export, one measured dashboard improvement, and a status normalisation with a safe release plan. Design and trade-offs are in [SOLUTION.md](SOLUTION.md).

## Stack

Rails 8.1.4 · Ruby 3.4.10 (`.ruby-version`) · PostgreSQL 17 · Propshaft + importmap · Tailwind (standalone binary) · Solid Queue/Cache/Cable on the one database.

## Run locally

Docker provides Postgres; nothing else is needed beyond Ruby and Bundler.

```sh
docker compose up -d   # Postgres 17 on localhost:5434, user/password: workhappy/password
bin/setup              # bundle install, db:prepare, then starts bin/dev
```

The app is on http://localhost:3002. On later runs, `bin/dev` alone starts the server and the Tailwind watcher.

To use your own Postgres instead of Docker, point `config/database.yml`'s `local` block at it.

## Checks

```sh
bin/rspec                        # the specs; system specs drive headless Chrome via Cuprite
bin/ci                           # rubocop, brakeman, bundler-audit, importmap audit, then the specs
bundle exec lefthook install     # optional: run the same gate as a pre-commit hook
```
