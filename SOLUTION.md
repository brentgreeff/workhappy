# SOLUTION

Run instructions are in [README.md](README.md).

Claude code was used - prompts and reasoning behind each step in [PROMPTS.md](PROMPTS.md).

## Assumptions

The brief describes a ten-year-old app but does not supply one.

- **The app is a small Rails 8.1 / PostgreSQL 17 scaffold. What makes it "legacy" is the seeded data: a free-text `status` column holding every spelling the brief lists (`complete`, `comp`, `done`, `n/a`, empty, null) and a `responses_json` column where answers are sometimes integers, sometimes strings, sometimes null, sometimes missing, sometimes not an object at all.

- **A company admin is a user who belongs to a company.** There is one role. The signed-in user's company is the tenant for everything (`Current.company`); no request ever carries a company id param that the server trusts.
- **Entities are as the brief lists them**: companies, employees, assessments with `company_id`, `employee_id`, `employee_email`, `status`, `responses_json`, `created_at`. `employee_email`.

- **The scoring rule is invented** - Brief does not define one.

- **Numbers were measured on a laptop**, on a seeded tenant, not on production.

## Task 1: company-scoped CSV export

| Requirement | What was built |
|---|---|
| Own company only, never a client-supplied company id | The export is created from `Current.company.exports` and its rows from `Current.company.assessments`. A composite foreign key stops an assessment ever pointing at another company's employee. |
| Two filters: date range and status | One filter object (`AssessmentFilter`) shared by the dashboard and the export. Dates that do not parse and reversed ranges are rejected rather than silently widening the query. |
| Redact free text and personal identifiers | The file holds `id, created_at, status, score` and nothing else. No email, no answers, no comments. Status is the canonical value or a fixed `unmapped` marker, never the raw stored string. |
| Minimal TypeScript UI | One Stimulus controller in TypeScript. The dashboard's filter form has an Export CSV button; the controller posts the form's fields using fetch, then polls the export every two seconds. The status reads Queued, Processing, then "Ready: N rows" with a Download link, or the failure message. |
| Streaming or asynchronous | **Asynchronous, with Solid Queue.** Heroku's router drops any response that goes 30 seconds without a byte. The job writes the file in batches of 1,000 rows to a temp file, attaches it with Active Storage, and marks the export ready with its row count. One export per company runs at a time. Exports are purged after a day. asynchronous does not block the web dyno|
| Nothing sensitive in logs | `responses_json`, answers, comments, email and names are in `filter_parameters`. The export writes a row count and nothing about the rows. The job reads `responses_json` only to compute the score and never writes it out. |

Operational notes for a Heroku-like deploy: Active Storage's disk service cannot work because the worker writes the file and the web dyno serves it, so production is configured for S3 via config vars (untested against a live bucket in this repository). The `Procfile` runs the Solid Queue supervisor inside Puma with a `release` phase for migrations.

## Task 2: dashboard performance and the score

### The score

The brief says the score is "sometimes blank or obviously off" and must be "consistently present and correct under normal circumstances", but never defines it. Answers are ratings, not right or wrong, so any rule is an assumption. It is written as a table so it can be read in one glance and changed as data:

```ruby
POINTS = {
  "posture"  => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 },
  "screen"   => { ... same ... }, "chair" => { ... }, "breaks" => { ... }, "lighting" => { ... }
}
MIN_ANSWERS = 3
```

The score is the mean of the mapped points over the questions that have a mappable answer, rounded to a whole number. An answer counts only when it is an integer, or a string of digits. A null, a missing key, `"n/a"`, a 6, or the free-text `comments` key never becomes a number. "blank or obviously off" came from: averaging over missing keys, or `to_i` on `"n/a"` giving zero, produces a wrong number silently. A lookup cannot.

When there is no score the dashboard says why, so an admin knows whether to chase the employee or the data: **No answers** (nothing stored, or no question answered), **Invalid answers** (questions answered, none usable), **Insufficient answers** (one or two usable, three needed). The export leaves the cell blank in all three cases. The same function serves the dashboard and the export, so they always agree.

### The measured improvement: one index

**The problem.** The dashboard lists a company's assessments newest first, fifty per page, with the two filters. Before the change the only useful index on the table was `company_id`. For a large company Postgres had to read every one of its rows, sort all of them by date, and keep fifty, on every page load. That cost grows with the table. It is the brief's "slow with many records".

**The change.** One index, `assessments (company_id, created_at, id)`, built concurrently so the table takes no lock while it builds. With it the page query walks the index in date order and stops after fifty entries, a date range becomes an index condition instead of a filter over every row, and the `id` column makes the order exact so no sort node remains at all.

**How it was measured.** Three rake tasks in the repo, so anyone can rerun them (see README, "Measuring the dashboard"):

- `assessments:seed_large` creates a benchmark tenant, Atlas Manufacturing, with the same messy data as the demo seed. Numbers below are for **2,000,000 assessments**.
- `assessments:explain` prints `EXPLAIN (ANALYZE, BUFFERS)` for the count and page statements in three schema states: without the dashboard index, with a two-column candidate, and with the dashboard index.
- `assessments:bench` times the count statement, the page statement, and the whole request through the app (signed in as the tenant's admin) for four scenarios, first without the dashboard index and then with it.

Both tasks force each schema state inside a database transaction that is rolled back, so one run prints before and after wether the index exists already or not. Each task also records whether the index existed at the start and restores exactly that at the end.

**Numbers, 2,000,000 rows, one run of `assessments:bench`, whole request through the app, in milliseconds:**

| Scenario | Before | After |
|---|---|---|
| Page 1, no filter | 546 | 55 |
| Page 200, no filter | 626 | 70 |
| One-year date window | 512 | 54 |
| Status = completed | 1,306 | 428 |

The page statement on its own went from **144 ms to 0.03 ms**. The plans show why:

```text
Before (page, no filter)                     After
Limit                                        Limit
  Sort (top-N heapsort)                        Index Scan Backward using
    Parallel Seq Scan on assessments             index_assessments_on_company_id_and_created_at_and_id
      rows=2,000,000                               rows=50, no sort node
Execution Time: 144 ms                       Execution Time: 0.03 ms
```

**Why this index and not something else.**

- It leads on `company_id`, so it is a tenant index and the multi-tenant scoping gets cheaper too.
- The three-column form was chosen over `(company_id, created_at)` because the plans showed the two-column one still needed an incremental sort for the `id` tie-break. The extra column costs eight bytes an entry and removes the last sort.
- A `status` index would do nothing yet: the status filter is `LOWER(TRIM(status))` so that legacy spellings match, and no ordinary index serves an expression it was not built on. That is fixed by Task 3, after which a plain index on the constrained column becomes possible.
- Keyset pagination, caching the count, or dropping the page total were all bigger changes to the page for smaller gains. The brief asked for the smallest reasonable change.

**What it does not fix yet**

- The page count ("Page 1 of 40,000") is bounded by how many rows match, not by sorting. A date window makes it an index-only scan (81 ms to 24 ms).
- The status filter is still slow (428 ms after) because of the expression above.
- Build time: 6 seconds concurrently at 2M rows. The migration uses `algorithm: :concurrently` and `disable_ddl_transaction!`; a concurrent build that fails leaves an invalid index that must be dropped before retrying.

**Guards.** A spec asks Postgres for the page plan on a seeded company and asserts the index is used and no Sort node appears; it failed before the migration and passes after. A request spec asserts the page runs the same number of statements for one row as for fifty, so a future column cannot reintroduce a per-row query.

## Task 3: status normalisation and release plan

To follow.
