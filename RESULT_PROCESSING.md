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

## Architecture: who owns what

Domain logic moved out of `ResultProcessor` and into a new
`ResultCategorizer` class invoked by callbacks on `Result`. The
processor is now a thin shim for parsers; the model+categorizer is the
single chokepoint for cap / pending / IIIю logic regardless of how a
row is created or updated.

```
Parser → BaseParser#add_result → ResultProcessor#add_result
                                        ↓
                                 Result.create! / find_by
                                        ↓
                            Result before_save → ResultCategorizer#before_save
                            Result after_save  → ResultCategorizer#after_save
```

Any direct caller (`Result.create!`, `result.update!`, admin UI, console)
goes through the same callback path. The processor is no longer
gatekeeping — callers can bypass it entirely and the domain rules still
apply.

## ResultProcessor (slim)

File: `app/processors/result_processor.rb`.

- `ResultProcessor.new(params).add_result` — **insert-only**. Resolves
  membership, runs `find_by(membership_id, group_id, date)`, returns the
  existing row unchanged if found, or `Result.create!`s a new one.
  Never updates existing rows. The IOF parser re-run downgrade bug is
  structurally impossible here.
- `ResultProcessor.new(params, result).update_result` — sparse update
  against a preset row. Slices params to `category_id` / `status`,
  no-ops when nothing differs from the current values.

The processor doesn't make cap / pending / IIIю decisions anymore —
those happen inside the model callback.

## ResultCategorizer (domain logic)

File: `app/processors/result_categorizer.rb`. Invoked from `Result`'s
`before_save` and `after_save` callbacks, delegated via thin private
methods on the model (`run_categorizer_before_save`,
`run_categorizer_after_save`). State (`@achieved_category_id`,
`@processed`) lives on a memoized categorizer instance so it persists
between the two callback phases.

### Two phases

**`before_save`** — guards → `destroy_all` stale children → `apply_cap`:
1. Bail if `skip_processing` or `parent_result_id.present?` (recursion
   guard — children created by the cap never re-enter).
2. Bail if `should_reprocess?` returns false.
3. Set `@processed = true`.
4. `child_results.destroy_all` unless this is a new record.
5. `apply_cap` — runs `better_category?`; if eligible, either rewrites
   `category_id` to `min(best_category_id, 4)` and sets status to
   CAPPED (stashing the original in `@achieved_category_id`), or sets
   status to CONFIRMED.

**`after_save`** — same guards → create derivatives:
1. Bail unless `@processed`.
2. Create PENDING child if `@achieved_category_id` was stashed.
3. Create IIIю child if `check_three_results?`.
4. Reset `@achieved_category_id` and `@processed`.

### Reprocess triggers (`should_reprocess?`)

- `new_record?`, OR
- `will_save_change_to_category_id?`, OR
- `will_save_change_to_status?`, OR
- `will_save_change_to_date?`, OR
- `membership_runner_changing?` (membership swap to a **different runner**).

The membership trigger compares the old membership's `runner_id` to the
new one's. A same-runner swap (e.g., club change for the same person)
is **not** a reprocess.

### `skip_processing` escape hatch

`attr_accessor :skip_processing` on `Result`. Set to `true` to bypass
the entire callback. Used by:
- Test fixtures that need to construct a row with explicit
  category/status without triggering the cap (the controller spec's
  `prior_result`, the model spec's `pending_result`).
- Callers that want to set state without re-running domain rules.

### `better_category?`

A new/updated result is "better" (eligible for `confirmed`/`capped`) if:
- The category isn't NO_CATEGORY, AND
- Either the group is the REDUCTION sentinel, OR
- The runner has no current confirmed category for the race date, OR
- The category id is strictly lower than the current, OR
- The category id equals the current AND this race is more recent.

### `check_three_results?`

- Gates: category is not NO_CATEGORY, date ≥ 2024-03-25, runner is a
  junior on the race date, runner has no category better than IIIю,
  runner has ≥3 results since 2024-03-25.
- **Intentional**: the guard is `< 9` (not `<= 9`), so subsequent
  finishes after a junior already holds IIIю still create a new
  IIIю row. This refreshes the 2-year validity per Classification §1.7.
- Side effect: very active juniors accumulate one IIIю row per finish
  after the third; `category_on_date` selects the most recent via
  `ORDER BY category_id ASC, date DESC LIMIT 1`.

### Cap decomposition quirk

Worth knowing: once a result is capped, `category_id` in the DB is the
post-cap value (4), not the originally-achieved category. The original
only lives in the PENDING child row. On any subsequent reprocess (date
change, runner swap, etc.) the cap sees `category_id = 4` and computes
`needs_pending? = (4 < 4) → false` — no new PENDING child gets created.

In production this rarely matters because re-saving a capped result is
itself rare. The categorizer spec uses `skip_processing: true` at
creation to isolate the cap from this quirk when testing reprocess
triggers (`date change`, `different-runner swap`).

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
| 4 | `best_category_id` nil safety                | **N/A.** Schema default is 10; processor never receives nil.                                                                        |
| 5 | Param string vs int coercion                 | **Fixed** in `ResultProcessor#initialize`.                                                                                          |
| 6 | Stale PENDING on update-to-worse-category    | **Resolved by callback.** `child_results.destroy_all` runs in `ResultCategorizer#before_save` on any reprocess trigger.              |
| 7 | Status-only update swallowed by early return | **N/A.** Old `handle_update_result` removed; the callback handles status changes directly.                                          |
| 8 | Auxiliary row counts on heavy-junior history | Documented above; works correctly via `category_on_date` ordering.                                                                  |
| 9 | IOF parser re-run downgrading existing rows  | **Structurally fixed.** `add_result` is insert-only; existing rows are returned unchanged. The old `params["status"] ||= UNCONFIRMED` is gone. |
| 10 | Cap decomposition on reprocess              | **Documented quirk.** Re-saving a capped row sees the post-cap `category_id` and doesn't recreate the PENDING child. Use `skip_processing: true` if isolation is needed. |

## Migrations added during this work

- `db/migrate/20260523094611_add_parent_result_to_results.rb`
- `db/migrate/20260523095609_cascade_delete_parent_result_fk.rb`

## Test coverage map

- `spec/models/runner_spec.rb` — `junior_runner?` with date arg / string date.
- `spec/processors/result_processor_spec.rb`
  - String → int coercion of `category_id` / `group_id`.
  - `add_result` insert-only behavior (returns existing without update).
  - `update_result` with category change, status-only change, sparse params, no-op when unchanged.
  - CAPPED vs CONFIRMED status decision via callback through `update_result`.
  - `parent_result_id` linkage on both PENDING and IIIю rows.
  - Cascade on `destroy` and on raw `delete_all` (DB FK).
  - Stale child cleanup on category-change via `update_result`.
- `spec/processors/result_categorizer_spec.rb` — categorizer-specific behaviors:
  - `skip_processing: true` bypasses the callback entirely.
  - `parent_result_id` recursion guard (children created by the cap don't re-enter).
  - Date change as a reprocess trigger.
  - Same-runner membership swap = no reprocess; different-runner swap = reprocess.
- `spec/controllers/results_controller_spec.rb` — `pending_result_id`
  and `pending_category_name` exposed in the index JSON. Fixtures that
  need explicit state use `skip_processing: true` to bypass the cap.

After any backend change to `app/models/result.rb`,
`app/models/runner.rb`, `app/processors/result_processor.rb`, or
`app/processors/result_categorizer.rb`, run `bundle exec rspec` per
`CLAUDE.md`.
