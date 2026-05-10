---
phase: 02-model-test-coverage
plan: "02"
subsystem: model-tests
tags: [minitest, model-tests, edition, enum, validations, fixtures]
completed: "2026-05-10T22:07:50Z"
duration: ~8 minutes
tasks_completed: 2
tasks_total: 2
requirements_satisfied: [TEST-02]

dependency_graph:
  requires: []
  provides:
    - test/models/edition_test.rb (11 Edition model tests)
    - test/fixtures/editions.yml (enum label strings, explicit published field)
  affects:
    - test/models/edition_test.rb
    - test/fixtures/editions.yml

tech_stack:
  added: []
  patterns:
    - Minitest fixture mutation pattern (load fixture, mutate one field, assert)
    - assert_raises(ArgumentError) for invalid enum assignment (pre-valid? raise pitfall)
    - assert_predicate for positive validity assertions
    - YAML fixture enum label strings (spring/autumn) vs integer values

key_files:
  created: []
  modified:
    - test/fixtures/editions.yml
    - test/models/edition_test.rb

decisions:
  - Used assert_raises(ArgumentError) for invalid season test because Rails enum raises at assignment time, before valid? runs — assert_not record.valid? would itself raise and error the suite (per RESEARCH.md Pitfall 1)
  - Rubocop plan criterion for YAML fixture file cannot be satisfied as rubocop 1.86.1 treats all explicitly-passed files as Ruby; the Ruby test file passes rubocop cleanly; YAML fixture is valid YAML confirmed by successful test run
---

# Phase 2 Plan 02: Edition Model Tests Summary

Edition model tests and fixture update — season enum exhaustiveness, ArgumentError on invalid enum, day numericality boundaries (1..90), five presence validations, and published flag default.

## Tasks Completed

### Task 1: Update editions.yml with enum label strings and explicit published field

**Commit:** 673984b

**Changes (before → after):**

| Field | Before | After |
|-------|--------|-------|
| `one.season` | `1` (integer) | `spring` (label string) |
| `two.season` | `1` (integer) | `autumn` (label string) |
| `one.year` | `1` | `2025` |
| `two.year` | `1` | `2025` |
| `one.day` | `1` | `45` |
| `two.day` | `1` | `12` |
| `two.volume` | `1` | `2` |
| `two.issue_number` | `1` | `3` |
| `published` | absent | `false` (one), `true` (two) |
| `attention_bar` | `MyString` | dropped (nullable, not under test) |

**Why these changes:**
- Label strings (`season: spring`) exercise Rails' label-to-integer mapping at fixture load time, matching how application code interacts with the enum
- Explicit `published:` values make intent clear rather than relying on the DB default silently
- Dropping `attention_bar: MyString` keeps fixtures lean (nullable column, no validations)
- Distinct `day`/`volume`/`issue_number` values per fixture prevent tests from accidentally passing on coincident defaults

### Task 2: Write Edition model tests

**Commit:** f8e8135

**Test results:** `11 runs, 28 assertions, 0 failures, 0 errors, 0 skips`

**Tests added:**

| Test name | Key assertion | Notes |
|-----------|---------------|-------|
| `season enum defines all four values` | `assert_equal({"spring"=>0,...}, Edition.seasons)` | Exhaustiveness check |
| `invalid season raises ArgumentError` | `assert_raises(ArgumentError) { Edition.new(season: :invalid_season) }` | ArgumentError pitfall avoided |
| `is valid with day at boundary values` | `assert_predicate edition, :valid?` for day=1 and day=90 | Both boundaries valid |
| `is invalid with day below 1` | `assert_not edition.valid?` + `assert_includes errors[:day], "must be in 1..90"` | Out-of-range below |
| `is invalid with day above 90` | `assert_not edition.valid?` + `assert_includes errors[:day], "must be in 1..90"` | Out-of-range above |
| `is invalid without year` | `assert_not edition.valid?` + `assert_includes errors[:year], "can't be blank"` | Presence |
| `is invalid without season` | `assert_not edition.valid?` + `assert_includes errors[:season], "can't be blank"` | Presence |
| `is invalid without day` | `assert_not edition.valid?` + `assert_includes errors[:day], "can't be blank"` | Presence |
| `is invalid without volume` | `assert_not edition.valid?` + `assert_includes errors[:volume], "can't be blank"` | Presence |
| `is invalid without issue_number` | `assert_not edition.valid?` + `assert_includes errors[:issue_number], "can't be blank"` | Presence |
| `published defaults to false` | `assert_equal false, Edition.new.published` | DB default |

## Test Run Output

```
Running 11 tests in a single process (parallelization threshold is 50)
Run options: --seed 65110

# Running:

...........

Finished in 0.046054s, 238.8476 runs/s, 607.9757 assertions/s.
11 runs, 28 assertions, 0 failures, 0 errors, 0 skips
```

## Rubocop Result

- `bin/rubocop test/models/edition_test.rb` — 1 file inspected, no offenses detected

Note: `bin/rubocop test/fixtures/editions.yml` produces a false positive (`Lint/Syntax: unexpected token tCOLON`) because rubocop 1.86.1 attempts to parse YAML as Ruby when files are passed explicitly. The YAML file is valid and loads correctly in the test suite — the false positive is a rubocop limitation, not a file content issue. The Ruby test file passes rubocop cleanly.

## ArgumentError Pitfall Avoided

The invalid-season test correctly uses:
```ruby
assert_raises(ArgumentError) { Edition.new(season: :invalid_season) }
```

It does NOT use `assert_not Edition.new(season: :invalid).valid?` — which would itself raise `ArgumentError` before `valid?` runs, causing the test to error rather than fail. This is per RESEARCH.md Pitfall 1 and PATTERNS.md Enum ArgumentError Pattern.

## Deviations from Plan

None in implementation. One plan criterion note:

**[Rule 1 - Plan Accuracy] Rubocop YAML false positive**
- **Found during:** Task 2 verification
- **Issue:** `bin/rubocop test/models/edition_test.rb test/fixtures/editions.yml` exits non-zero because rubocop 1.86.1 parses explicitly-passed YAML files as Ruby syntax, producing `Lint/Syntax: unexpected token tCOLON`
- **Root cause:** rubocop's `AllCops: Exclude` only applies to auto-discovered files, not explicitly-passed targets; `--force-exclusion` flag would be needed but the plan's command doesn't use it
- **Assessment:** The fixture is valid YAML and loads correctly. The Ruby test file passes rubocop. The plan criterion cannot be satisfied as written without either `--force-exclusion` or limiting rubocop to the Ruby file only.
- **Action taken:** No code change. Documented as a planning artifact.

## Known Stubs

None. All test bodies are complete with real assertions.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Test-only files, no production surface added.

## Requirements Satisfied

- [x] TEST-02: Edition model tests cover season enum values, day numericality (1–90), year/season/day/volume/issue_number presence, and published flag default

## Self-Check

Committed files exist and tests pass:
- `test/fixtures/editions.yml` — present, valid YAML with label strings
- `test/models/edition_test.rb` — present, 11 test methods, 28 assertions, 0 failures
- Commit 673984b (Task 1) — exists on worktree-agent-adbb09bf6103db041
- Commit f8e8135 (Task 2) — exists on worktree-agent-adbb09bf6103db041
