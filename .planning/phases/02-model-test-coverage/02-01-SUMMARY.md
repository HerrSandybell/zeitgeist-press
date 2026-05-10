---
phase: 02-model-test-coverage
plan: "01"
subsystem: testing
tags: [minitest, fixtures, newspaper, model-tests, rails]

requires:
  - phase: 01-production-security
    provides: Newspaper model with name presence validation and has_many :editions

provides:
  - Real Minitest tests for Newspaper model (name presence, fixture validity, has_many editions reflection)
  - newspapers.yml with meaningful fixture names (The Daily Chronicle, The Evening Post)

affects: [02-02, 02-03]

tech-stack:
  added: []
  patterns: [minitest model test with assert_predicate fixture check, reflect_on_association macro check]

key-files:
  created: []
  modified:
    - test/models/newspaper_test.rb
    - test/fixtures/newspapers.yml

key-decisions:
  - "Use reflect_on_association(:editions).macro for structural association check rather than dependent: destroy behavior test"
  - "Fixture keys one/two preserved for downstream editions fixtures that reference newspaper: one"

patterns-established:
  - "Pattern 1: Model validation test — Newspaper.new(name: nil).valid? then assert_includes errors[:name]"
  - "Pattern 2: Fixture validity test — assert_predicate fixture_accessor(:one), :valid?"
  - "Pattern 3: Association reflection test — Newspaper.reflect_on_association(:assoc).macro == :macro"

requirements-completed: [TEST-01]

duration: 2min
completed: 2026-05-10
---

# Phase 2 Plan 01: Newspaper Model Test Coverage Summary

**Three Minitest tests covering name presence validation and has_many :editions association reflection, with meaningful fixture names replacing MyString placeholders**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-10T22:04:47Z
- **Completed:** 2026-05-10T22:06:11Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- newspapers.yml updated with meaningful names (The Daily Chronicle, The Evening Post), fixture keys one/two preserved
- newspaper_test.rb written with three tests: name invalid, name valid via fixture, has_many editions reflection
- `bin/rails test test/models/newspaper_test.rb` reports 3 runs, 6 assertions, 0 failures, 0 errors
- `bin/rubocop test/models/newspaper_test.rb` exits 0, no offenses
- TEST-01 satisfied: Newspaper model tests cover name presence validation and has_many :editions

## Task Commits

1. **Task 1: Update newspapers.yml with meaningful fixture names** - `159574c` (chore)
2. **Task 2: Add Newspaper model tests** - `5930700` (test)

**Plan metadata:** see final metadata commit

## Files Created/Modified
- `test/fixtures/newspapers.yml` - Replaced MyString with The Daily Chronicle / The Evening Post
- `test/models/newspaper_test.rb` - Three real test blocks replacing scaffold stub

## Fixture Changes

**Before:**
```yaml
one:
  name: MyString

two:
  name: MyString
```

**After:**
```yaml
one:
  name: The Daily Chronicle

two:
  name: The Evening Post
```

## Tests Added

| Test | Assertion |
|------|-----------|
| `test "is invalid without name"` | `Newspaper.new(name: nil).valid?` is false, `errors[:name]` includes "can't be blank" |
| `test "is valid with name"` | `newspapers(:one)` passes `valid?` predicate |
| `test "has many editions"` | `Newspaper.reflect_on_association(:editions).macro == :has_many` |

## Test Run Output

```
Running 3 tests in a single process (parallelization threshold is 50)
Run options: --seed 64306

# Running:

...

Finished in 0.023508s, 127.6186 runs/s, 255.2372 assertions/s.
3 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

## Rubocop Result

```
Inspecting 1 file
.

1 file inspected, no offenses detected
```

Note: `bin/rubocop test/fixtures/newspapers.yml` produces a parse error because rubocop treats YAML as Ruby. The plan's acceptance criterion for rubocop on the YAML file is not achievable — rubocop does not lint YAML files (they are not in its target files list). The Ruby test file passes cleanly.

## Decisions Made
- Used `reflect_on_association(:editions).macro` for structural check rather than testing destroy cascade behavior — per RESEARCH.md Open Question 1, avoids scope creep
- Fixture keys `one` and `two` preserved since editions.yml will reference `newspaper: one` and `newspaper: two`

## Deviations from Plan

None for code changes. One acceptance criterion note:

**Rubocop on YAML file:** The plan specifies `bin/rubocop test/models/newspaper_test.rb test/fixtures/newspapers.yml` should exit 0. Running rubocop explicitly on a YAML file causes a parse error (rubocop attempts to parse it as Ruby). YAML files are not in rubocop's default target list. The Ruby test file passes cleanly; no action needed on the YAML file.

## Issues Encountered
- Test database not yet prepared on worktree; resolved with `bin/rails db:test:prepare`

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Newspaper model test pattern established; Plans 02-02 and 02-03 can repeat this pattern for Edition and Story
- TEST-01 satisfied
- No blockers

---
*Phase: 02-model-test-coverage*
*Completed: 2026-05-10*
