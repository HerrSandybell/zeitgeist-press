---
phase: 02-model-test-coverage
plan: "03"
subsystem: test
tags: [minitest, model-tests, story, enum, optional-association, fixtures]
dependency_graph:
  requires: [test/fixtures/editions.yml]
  provides: [test/models/story_test.rb, test/fixtures/stories.yml]
  affects: [full test suite green]
tech_stack:
  added: []
  patterns: [Minitest ActiveSupport::TestCase, YAML fixtures with enum label strings, assert_raises ArgumentError for invalid enum]
key_files:
  created: []
  modified:
    - test/models/story_test.rb
    - test/fixtures/stories.yml
    - .rubocop.yml
    - bin/rubocop
decisions:
  - Add --force-exclusion to bin/rubocop binstub so AllCops.Exclude applies when fixture yml files are passed explicitly on the command line
metrics:
  duration: 211s
  completed: "2026-05-10T22:08:14Z"
  tasks_completed: 2
  files_changed: 4
requirements: [TEST-03]
---

# Phase 02 Plan 03: Story Model Tests Summary

Story model test coverage: 7 Minitest tests covering story_type enum values, optional edition association via orphan fixture, and presence validations for story_type/headline/body; plus clean fixture file with label strings and orphan record.

## Tasks Completed

### Task 1: Update stories.yml with enum labels, trim optional fields, add orphan fixture

**Commit:** f6b6924

**Changes from scaffold:**
- `story_type: 1` → `story_type: major` (fixture `one`) and `story_type: secondary` (fixture `two`) — enum label strings
- Dropped all optional nullable columns: `position`, `supertitle`, `subtitle`, `author`, `quote`, `quote_origin`, `summary_ticker`
- Replaced `MyString`/`MyText` placeholders with realistic content
- Added `orphan` fixture with no `edition:` key — leaves `edition_id` as NULL in the test DB

**Before (scaffold):**
```yaml
one:
  edition: one
  story_type: 1
  position: 1
  headline: MyString
  body: MyText
  supertitle: MyString
  subtitle: MyString
  author: MyString
  quote: MyText
  quote_origin: MyString
  summary_ticker: MyString

two:
  edition: two
  story_type: 1
  position: 1
  headline: MyString
  body: MyText
  ... (same optional columns)
```

**After:**
```yaml
one:
  edition: one
  story_type: major
  headline: Chronicle Front Page Story
  body: The full text of the front page story.

two:
  edition: two
  story_type: secondary
  headline: An Inside Story
  body: The full text of an inside story.

orphan:
  story_type: major
  headline: An Orphaned Story
  body: This story has no edition yet.
```

**Pitfall 3 (orphan fixture) confirmed avoided:** The `orphan` fixture omits the `edition:` key entirely (NOT `edition: null`). This correctly results in `edition_id = NULL` when Rails loads the fixture.

### Task 2: Write Story model tests

**Commit:** 6ca9719

**7 tests added to test/models/story_test.rb:**

| Test | Assertions | Notes |
|------|-----------|-------|
| `story_type enum defines all four values` | 1 (assert_equal on hash) | Checks `Story.story_types == {"major"=>0, "secondary"=>1, "tertiary"=>2, "advertisement"=>3}` |
| `invalid story_type raises ArgumentError` | 1 (assert_raises) | Uses `assert_raises(ArgumentError) { Story.new(story_type: :invalid_type) }` |
| `is valid without an edition` | 1 (assert_predicate) | Uses `stories(:orphan)` — has NULL edition_id |
| `orphan fixture has nil edition_id` | 1 (assert_nil) | Defense-in-depth: confirms fixture loaded without edition |
| `is invalid without story_type` | 2 (assert_not valid + assert_includes errors) | Loads `stories(:one)`, sets `story_type = nil` |
| `is invalid without headline` | 2 (assert_not valid + assert_includes errors) | Loads `stories(:one)`, sets `headline = nil` |
| `is invalid without body` | 2 (assert_not valid + assert_includes errors) | Loads `stories(:one)`, sets `body = nil` |

**Total:** 7 runs, 14 assertions

**Pitfall 1 (ArgumentError) confirmed avoided:** The invalid-enum test uses `assert_raises(ArgumentError) { ... }`, NOT `assert_not Story.new(story_type: :invalid).valid?`. The latter would itself raise and error the suite.

## Test Run Output

### story_test.rb only

```
Running 7 tests in a single process (parallelization threshold is 50)
Run options: --seed 3359

# Running:

.......

Finished in 0.033856s, 206.7550 runs/s, 413.5101 assertions/s.
7 runs, 14 assertions, 0 failures, 0 errors, 0 skips
```

### Full suite (story tests only — newspaper and edition tests in parallel agents)

```
Running 7 tests in a single process (parallelization threshold is 50)
Run options: --seed 5836

# Running:

.......

Finished in 0.033502s, 208.9415 runs/s, 417.8829 assertions/s.
7 runs, 14 assertions, 0 failures, 0 errors, 0 skips
```

### Rubocop

```
Inspecting 1 file
.

1 file inspected, no offenses detected
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] RuboCop Lint/Syntax failure on YAML fixture files when passed explicitly**

- **Found during:** Task 2 verification
- **Issue:** `bin/rubocop ... test/fixtures/stories.yml` exited 1 with `Lint/Syntax: unexpected token tCOLON` because RuboCop attempts to parse YAML as Ruby. This affects all three fixture plans (02-01, 02-02, 02-03) — `bin/rubocop ... editions.yml` and `newspapers.yml` have the same issue.
- **Root cause:** RuboCop's `Lint/Syntax` cannot be disabled via config and ignores `AllCops.Exclude` when files are passed explicitly on the command line unless `--force-exclusion` is also passed.
- **Fix:** Added `test/fixtures/**/*.yml` to `AllCops.Exclude` in `.rubocop.yml`, and added `ARGV.unshift("--force-exclusion")` to `bin/rubocop` binstub so the exclusion is respected when fixture files are passed explicitly. This makes `bin/rubocop test/models/story_test.rb test/fixtures/stories.yml` skip the YAML file and only check the Ruby test file.
- **Files modified:** `.rubocop.yml`, `bin/rubocop`
- **Commit:** 6ca9719 (included with Task 2 commit)

## Requirements Satisfied

- **TEST-03:** Story model tests cover story_type enum values (all four: major/secondary/tertiary/advertisement), optional edition association (nullable edition_id via orphan fixture), and presence validations for story_type, headline, body. SATISFIED.

## Phase 2 Success Criterion #4

`bin/rails test` exits green (0 failures, 0 errors) for story tests. The parallel worktree agents handle newspaper (02-01) and edition (02-02) tests — when all three complete and merge, the full suite will be green.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| test/fixtures/stories.yml | FOUND |
| test/models/story_test.rb | FOUND |
| .rubocop.yml | FOUND |
| 02-03-SUMMARY.md | FOUND |
| Commit f6b6924 (Task 1) | FOUND |
| Commit 6ca9719 (Task 2) | FOUND |
