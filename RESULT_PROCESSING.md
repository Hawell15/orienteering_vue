# Result Processing — Domain Notes

Context document for changes to results, categories, and the result processor.
Originally written after a session walking through the Moldovan orienteering
classification rules ("Спортивная классификация Республики Молдова по
спортивному ориентированию 2023-2025"). Reference PDF (Russian): "Классификация_03_24".

## Domain primer

### Categories (lower id = better)

| id | Code        | Russian       | Notes                              |
|----|-------------|---------------|------------------------------------|
| 1  | МСМК РМ     | мастер межд.  | International Master, Ministry-confirmed |
| 2  | МС РМ       | мастер        | Master, Ministry-confirmed |
| 3  | КМС РМ      | кандидат      | Candidate Master, Ministry-confirmed |
| 4  | I разряд    | -             | Highest non-Ministry rank |
| 5  | II разряд   | -             | -                                  |
| 6  | III разряд  | -             | -                                  |
| 7  | Iю          | юношеский     | **Junior only** (≤17 by year of birth) |
| 8  | IIю         | юношеский     | **Junior only** |
| 9  | IIIю        | юношеский     | **Junior only**; also auto-granted on 3rd finish |
| 10 | б/р         | без разряда   | NO_CATEGORY_ID — sentinel for "no rank" |

`Category::NO_CATEGORY_ID = 10`.

### Runner state

- `runners.category_id` (NOT NULL DEFAULT 10) — the runner's **currently
  valid** category. Valid for the category's `validaty_period` years from
  the latest CONFIRMED earning/refresh; falls back to 10 when expired.
- `runners.best_category_id` (DEFAULT 10) — best category ever achieved,
  lifetime, no expiry. Monotonically improves.
- Re-derived from results by `Runner#update_runner_category` /
  `Runner#category_on_date(date)` (`app/models/runner.rb`).

### Junior eligibility

- "Юношеские разряды выполняются спортсменами не старше 18 лет по году
  рождения" (Classification §1.5).
- Implemented as `Runner#junior_runner?(date = Date.today)` —
  `date.year - yob < 18`. **Always evaluate against the competition date**,
  not `Time.now`, otherwise historical races for now-adult runners get the
  rule wrongly stripped. The SQL in `Result.with_runner_category_on_date`
  already does this correctly.

### Validity period (Classification §1.7)

- МСМК: 4 years
- МС, КМС: 3 years
- I/II/III + Iю/IIю/IIIю: 2 years
- Period restarts on each **confirmation** (a new race result re-earning
  the same or better category counts as a confirmation).
- If the period lapses with no confirmation, the runner's effective
  category drops one step (Annex 1 §3.4) — modelled by treating expired
  results as invisible to `Runner#category_on_date`.

### IIIю auto-grant (§1.3)

A junior who **finishes within control time on 3 separate races** earns
IIIю automatically.

- The federation introduced this rule on **2024-03-25**; races before that
  date don't count.
- Roman's DB invariant: **DNF / DSQ rows are not inserted at all**, so
  counting any `runner.results` row in the date range is equivalent to
  counting valid finishes.

### Title categories (МСМК/МС/КМС) require Ministry approval

- Categories 1–3 are conferred by Министерство образования и науки РМ
  (Annex 1 §1.1) after a separate paperwork process.
- A race can fulfil the norm, but the runner is not formally promoted
  until the Ministry order is published.
- We model this by:
  1. Creating a PENDING child result with the actually achieved title
     category (`group_id = TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID = 2320`).
  2. Capping the main race result to `min(best_category_id, 4)` so that
     `Runner#category_on_date` returns a category the runner is allowed
     to use without Ministry approval.
  3. Marking the main result with status `capped`.

## Result statuses

| status        | Romanian (frontend) | Meaning                                                  |
|---------------|---------------------|----------------------------------------------------------|
| `unconfirmed` | Fără îndeplinire    | Did not fulfil any category at this race                |
| `confirmed`   | Îndeplinit          | Fulfilled the displayed category                        |
| `pending`     | În așteptare        | Title category awaiting Ministry approval (child row)   |
| `capped`      | Plafonat            | Fulfilled a title, capped to a sub-Ministry category; linked to a `pending` child |

Defined in `Result::STATUSES`. Frontend label maps in
`app/frontend/components/Result/Table.vue` and `Group/Show.vue`.

## Special Group ids

| Constant                                | id   | Purpose                                              |
|-----------------------------------------|------|------------------------------------------------------|
| `Group::REDUCTION_CATEGORY_GROUP_ID`    | 2    | Sentinel group — always treated as `better_category?` |
| `Group::THREE_RESULTS_GROUP_ID`         | 1346 | Container for auto-granted IIIю rows                  |
| `Group::TITLE_CATEGORY_ACHIEVEMENT_GROUP_ID` | 2320 | Container for PENDING title rows                  |

## Parent/child linkage

Migration `20260523094611_add_parent_result_to_results.rb` adds
`results.parent_result_id` (self-FK). Migration
`20260523095609_cascade_delete_parent_result_fk.rb` upgrades the FK to
`ON DELETE CASCADE`.

- `Result#parent_result` / `Result#child_results`
  (`dependent: :destroy`) wire the relationship in Rails.
- Both PENDING (title) and CONFIRMED IIIю (three-results) auxiliary rows
  set `parent_result_id` to the main race result.
- Deleting the main result removes the children both via Rails callback
  (`destroy`) and DB cascade (raw `DELETE` / `delete_all`).

## ResultProcessor flow

File: `app/processors/result_processor.rb`.

### Two entry points

- `ResultProcessor.new(params).add_result` — for inserts; idempotent
  upsert keyed on `(membership_id, group_id, date)`.
- `ResultProcessor.new(params, result).update_result` — for sparse
  updates against a known row. `add_result` also routes to the update
  path when a result is preset.

### params fallback helpers

`current_date`, `current_category_id`, `current_group_id` prefer
`params[...]` and fall back to `result.<field>` when the result is
preset. All flow helpers (`better_category?`, `check_three_results?`,
`create_pending_result`, `add_tree_results_category`) use these so the
processor handles a sparse params hash on the update path.

### add_result high-level

1. If `@result` preset → `handle_update_result` (skip membership lookup).
2. Resolve `membership_id` via `add_membership_id`.
3. `find_by(membership_id, group_id, date)` to detect existing →
   if found, `handle_update_result`; otherwise continue.
4. `apply_pending_cap_if_needed` may rewrite `params["category_id"]` to
   `min(best, 4)` and set `params["status"] = CAPPED`; returns the
   originally-achieved category if a pending child should be created.
5. `Result.create!` the main row.
6. If a pending was warranted → `create_pending_result(achieved)` linked
   via `parent_result_id`.
7. `add_tree_results_category` — if the runner is a junior on the race
   date AND has ≥3 finishes since 2024-03-25 AND no current category
   better than IIIю, create a CONFIRMED IIIю row linked via
   `parent_result_id`.

### handle_update_result

- `category_changed`: `params["category_id"].present? && result.category_id != params["category_id"]`
- `status_changed`: same shape for status.
- Early-return if neither.
- If category changed: re-evaluate pending cap, **destroy stale
  `result.child_results`** (cascade also removes their DB rows), update
  main, re-create derivatives.
- Status-only changes apply without touching children.

### better_category?

A new result is "better" (= eligible for `confirmed`/`capped`) if:
- The category isn't NO_CATEGORY, AND
- Either the group is the REDUCTION sentinel, OR
- The runner has no current confirmed category for the race date, OR
- The category id is strictly lower than the current, OR
- The category id equals the current AND this race is more recent
  (counts as a confirmation/refresh).

### check_three_results?

- Returns true → triggers `add_tree_results_category`.
- Gates: category is not NO_CATEGORY, date ≥ 2024-03-25, runner is a
  junior on the race date, runner has no category better than IIIю,
  runner has ≥3 results since 2024-03-25.
- **Intentional**: the guard is `< 9` (not `<= 9`), so subsequent
  finishes after a junior already holds IIIю still create a new
  IIIю row. This **refreshes the 2-year validity** per Classification
  §1.7. Side effect: very active juniors accumulate one IIIю row per
  finish after the third; `category_on_date` selects the most recent
  via `ORDER BY category_id ASC, date DESC LIMIT 1`.

## Frontend wiring

### `app/frontend/components/Result/Table.vue`

- `formatStatus` maps `capped → "Plafonat"`.
- Capped cell renders as `<a href="/results/{pending_id}">Plafonat({pending_category_name})</a>`
  when a linked pending child exists; falls back to plain text otherwise.
- Hover title on capped cell: "Sportivul a îndeplinit categorie
  superioară ce trebuie confirmată în Minister".
- Save & delete emit `refresh` — the parent (`Index.vue`) does
  `window.location.reload()` so cascaded child rows and freshly-created
  PENDING rows appear immediately.

### `app/controllers/results_controller.rb#index_base_query`

Joins `Result.with_pending_title` (lateral subquery against
`parent_result_id + group_id + status`) and selects
`pending_result_id`, `pending_category_name` so the table can render the
link without an N+1.

## Audit decisions from the original review

These were resolved during the walkthrough — recording them so future
work doesn't relitigate or accidentally regress.

| # | Topic                                        | Decision                                                                                                                            |
|---|----------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| 1 | `junior_runner?` ignoring the race date      | **Fixed.** Takes a date arg, defaults to today; SQL siblings already correct.                                                       |
| 2 | `< 9` guard in `check_three_results?`        | **Intentional.** Re-creating IIIю rows refreshes the 2-year validity. Accepted duplicate rows.                                       |
| 3 | Counting non-finishes in the 3-race rule     | **N/A by data invariant.** DNF/DSQ never inserted. Hardcoded 2024-03-25 is the federation rule effective date.                       |
| 4 | `best_category_id` nil safety                | **N/A.** Schema default is 10; processor never receives nil. (No model-level defaulter — shoulda matcher conflict.)                |
| 5 | Param string vs int coercion                 | **Fixed** in `ResultProcessor#initialize`.                                                                                          |
| 6 | Stale PENDING on update-to-worse-category    | **Resolved by cascade.** `child_results.destroy_all` in `handle_update_result` on category change.                                  |
| 7 | Status-only update swallowed by early return | **Fixed.** Gate is `unless category_changed || status_changed`; pending logic only fires on category change.                         |
| 8 | Auxiliary row counts on heavy-junior history | Documented above; works correctly via `category_on_date` ordering. Optional future change: `find_or_initialize` to dedupe.            |

## Migrations added during this work

- `db/migrate/20260523094611_add_parent_result_to_results.rb`
- `db/migrate/20260523095609_cascade_delete_parent_result_fk.rb`

## Test coverage map

- `spec/models/runner_spec.rb` — `junior_runner?` with date arg / string date.
- `spec/processors/result_processor_spec.rb`
  - String → int coercion of `category_id` / `group_id`.
  - Sparse update path (preset result, missing params).
  - `update_result` with status-only param.
  - `add_result` with preset result routes to update without `add_membership_id`.
  - CAPPED vs CONFIRMED status decision.
  - `parent_result_id` linkage on both PENDING and IIIю rows.
  - Cascade on `destroy` and on raw `delete_all` (DB FK).
  - Stale child cleanup on category-change update.
- `spec/controllers/results_controller_spec.rb` — `pending_result_id`
  and `pending_category_name` exposed in the index JSON.

After any backend change to `app/models/result.rb`,
`app/models/runner.rb`, or `app/processors/result_processor.rb`, run
`bundle exec rspec` per `CLAUDE.md`.
