# Project guidance

## Backend changes & RSpec

After every backend change (Ruby code under `app/` — models, controllers, parsers, processors, lib), run the existing RSpec suite:

```
bundle exec rspec
```

- If any spec fails, **do not** auto-fix the spec and do not auto-revert the code change. Report the failing specs to the user — including the spec file, the failure message, and a short summary of why it likely fails — and let the user decide whether the code or the spec should be updated.
- For any new backend behavior introduced (new method, new controller action, new branch in existing logic), add corresponding RSpec coverage in the matching `spec/` subdirectory (e.g., a new method on `Runner` → add examples to `spec/models/runner_spec.rb`).

After the spec suite is green, run RuboCop in autocorrect mode against the files you changed in this turn:

```
bundle exec rubocop -A <path1> <path2> ...
```

- Only pass the files you actually modified — don't run it across the whole repo.
- If RuboCop reports offenses it cannot autocorrect, report them to the user (file, line, cop name) rather than silently leaving them or rewriting the code beyond the autocorrect.
