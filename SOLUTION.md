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

The brief says the score is "sometimes blank or obviously off" but never defines it. Answers are ratings, not right or wrong, so any rule is an assumption. It is written as a table, readable at a glance and changed as data:

```ruby
POINTS = {
  "posture"  => { 1 => 0, 2 => 25, 3 => 50, 4 => 75, 5 => 100 },
  "screen"   => { ... same ... }, "chair" => { ... }, "breaks" => { ... }, "lighting" => { ... }
}
MIN_ANSWERS = 3
```

The score is the mean of the mapped points, rounded. An answer counts only when it is an integer or a string of digits. A null, a missing key, `"n/a"`, a 6 or the free-text `comments` never becomes a number. That is where "blank or obviously off" comes from: averaging over missing keys, or `to_i` on `"n/a"` giving zero, produces a wrong number silently. A lookup cannot.

With no score the dashboard says why, so an admin knows whether to chase the employee or the data: **No answers**, **Invalid answers** (answered, none usable), **Insufficient answers** (fewer than three usable). The export leaves the cell blank. One function serves both, so they always agree.

### The measured improvement: one index

**The problem.** The dashboard lists a company's assessments newest first, fifty per page. The only useful index was `company_id`, so for a large company Postgres read every row, sorted them all by date and kept fifty, on every page load. That is the brief's "slow with many records".

**The change.** One index, `assessments (company_id, created_at, id)`, built concurrently so the table is not locked. The page query walks the index in date order and stops after fifty entries; the `id` column makes the order exact, so no sort remains.

**How it was measured.** Three rake tasks anyone can rerun (README, "Measuring the dashboard"):

```sh
bin/rails assessments:seed_large   # a tenant with 2,000,000 assessments of the same messy data
bin/rails assessments:explain      # EXPLAIN (ANALYZE, BUFFERS) without the index, with a two-column candidate, with the index
bin/rails assessments:bench        # count, page and whole-request times for four scenarios, before and after
```

`explain` and `bench` force each schema state inside a rolled-back transaction, so one run prints before and after, and they leave the index as they found it.

**Numbers**, 2,000,000 rows, whole request, in milliseconds:

| Scenario | Before | After |
|---|---|---|
| Page 1, no filter | 546 | 55 |
| Page 200, no filter | 626 | 70 |
| One-year date window | 512 | 54 |
| Status = completed | 1,306 | 428 |

The page statement on its own went from **144 ms to 0.03 ms**:

```text
Before (page, no filter)                     After
Limit                                        Limit
  Sort (top-N heapsort)                        Index Scan Backward using
    Parallel Seq Scan on assessments             index_assessments_on_company_id_and_created_at_and_id
      rows=2,000,000                               rows=50, no sort node
Execution Time: 144 ms                       Execution Time: 0.03 ms
```

**Why this index.** It leads on `company_id`, so tenant scoping gets cheaper too. The two-column `(company_id, created_at)` still needed a sort for the `id` tie-break; the third column removes it. A `status` index would do nothing yet: the filter is `LOWER(TRIM(status))` so legacy spellings match, and no plain index serves that until Task 3 fixes the data. Keyset pagination or dropping the page count were bigger changes for smaller gains.

**Not fixed.** The page count still scales with matching rows, and the status filter is still slow (428 ms) for the reason above. A failed concurrent build leaves an invalid index to drop before retrying.

**Guards.** A spec asserts the page plan uses the index with no Sort node; it failed before the migration. A request spec asserts one row and fifty rows run the same number of statements, so no per-row query creeps back.

## Task 3: status normalisation and release plan

To follow.
