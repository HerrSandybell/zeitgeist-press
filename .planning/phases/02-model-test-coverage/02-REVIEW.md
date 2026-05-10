---
phase: 02-model-test-coverage
reviewed: 2026-05-10T00:00:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - test/fixtures/editions.yml
  - test/fixtures/newspapers.yml
  - test/fixtures/stories.yml
  - test/models/edition_test.rb
  - test/models/newspaper_test.rb
  - test/models/story_test.rb
  - .rubocop.yml
  - bin/rubocop
findings:
  critical: 0
  warning: 5
  info: 2
  total: 7
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-05-10T00:00:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Eight files reviewed: three fixture files, three model test files, the RuboCop config, and the RuboCop binstub. Models cross-referenced against `app/models/` and `db/schema.rb` to verify test accuracy.

The tests are broadly correct — validations are exercised and the enum assertions match the real model definitions. However, there are five material gaps: missing association-level test coverage for dependent-destroy behavior, a structurally broken nil-season test, an absent belongs_to uniqueness gap, no coverage of the `newspaper_id` FK constraint on editions, and a fixture that carries a dangling `add_foreign_key` constraint against a nullable column. Two informational items flag missing `position` coverage and a trivial RuboCop fixture-exclusion that works but is broader than necessary.

---

## Warnings

### WR-01: `edition.season = nil` cannot exercise the nil-season validation path

**File:** `test/models/edition_test.rb:43`
**Issue:** The test sets `edition.season = nil` expecting an `"can't be blank"` validation error. However, `Edition#season` is backed by a Rails enum. Assigning `nil` to an enum attribute is not the same as clearing it — Rails 7+ enums accept `nil` as a value (it stores `NULL`) and the presence validator will catch it, but assigning the string `"nil"` or an invalid string would raise `ArgumentError` before validation runs. More critically, the companion test `"invalid season raises ArgumentError"` at line 8 confirms that only *invalid* symbols raise — `nil` is silently coerced to `NULL`. The real risk is that if the DB column had a `NOT NULL` constraint, the validation error message would differ from `"can't be blank"`. Cross-checking `db/schema.rb` line 21 confirms `season` is `t.integer "season"` with **no** `null: false`, so NULL can reach the DB if the Rails validation is removed. The test works by accident of the presence validator, but it does not verify enum-specific nil-rejection — a future dev removing the `presence: true` for `:season` (e.g., intending to make it optional) would see this test pass on `nil` while the enum constraint is gone.

**Fix:** Add an explicit assertion that distinguishes the enum nil path from a generic blank:
```ruby
test "is invalid without season" do
  edition = editions(:one)
  edition.season = nil
  assert_not edition.valid?
  assert_includes edition.errors[:season], "can't be blank"
  # Confirm the enum attribute itself reports nil, not a sentinel
  assert_nil edition.season
end
```

---

### WR-02: No test for `Edition` belonging to a `Newspaper` (required association)

**File:** `test/models/edition_test.rb` (absent)
**Issue:** `Edition` has `belongs_to :newspaper` (not optional), meaning `newspaper_id` is required at the DB level (`null: false` in `db/schema.rb` line 19) and enforced by Rails `belongs_to` implicit presence validation. There is no test confirming an `Edition` without a `newspaper` is invalid. If someone adds `optional: true` to the association or changes the FK constraint, nothing in the test suite will catch the regression.

**Fix:**
```ruby
test "is invalid without a newspaper" do
  edition = editions(:one)
  edition.newspaper = nil
  assert_not edition.valid?
  assert_includes edition.errors[:newspaper], "must exist"
end
```

---

### WR-03: `NewspaperTest` does not test dependent destroy of editions

**File:** `test/models/newspaper_test.rb:14`
**Issue:** The test at line 14 verifies the association macro (`has_many :editions`) exists via reflection, but does not verify that `dependent: :destroy` is in effect. Reflection on `:editions` tells you the association exists; it does not validate the `dependent` option. If `dependent: :destroy` were removed from `Newspaper`, `newspaper_test.rb` would still pass while orphaned `Edition` rows would silently accumulate.

**Fix:**
```ruby
test "destroying a newspaper destroys its editions" do
  newspaper = newspapers(:one)
  edition_id = newspaper.editions.first.id
  newspaper.destroy
  assert_not Edition.exists?(edition_id)
end
```

---

### WR-04: `EditionTest` does not test dependent destroy of stories

**File:** `test/models/edition_test.rb` (absent)
**Issue:** `Edition` declares `has_many :stories, dependent: :destroy`. Like WR-03, no test verifies the cascade behavior. A refactor removing `dependent: :destroy` would leave the test suite green while stories orphaned by edition deletion would still reference the deleted edition's FK — which `db/schema.rb` enforces via a hard `add_foreign_key "stories", "editions"` (line 52). In SQLite this constraint is not enforced by default, but the application's integrity assumption is violated.

**Fix:**
```ruby
test "destroying an edition destroys its stories" do
  edition = editions(:one)
  story_id = edition.stories.first.id
  edition.destroy
  assert_not Story.exists?(story_id)
end
```

---

### WR-05: `StoryTest` does not test `belongs_to :edition` reflection or optional status

**File:** `test/models/story_test.rb` (absent)
**Issue:** The `orphan` fixture correctly demonstrates that a `Story` without an `edition_id` is valid (tests at lines 12–18 cover this), but there is no reflection-level test confirming the association is declared `optional: true`. More importantly, the inverse — that a `Story` *with* a non-existent `edition_id` is invalid — is not tested. If someone changes `belongs_to :edition, optional: true` to `belongs_to :edition` (dropping optional), the orphan fixture would break at load time, but that breakage is indirect. Conversely, if `optional: true` were accidentally removed and the presence validation became strict, there is no test to catch it before the model change ships.

**Fix:**
```ruby
test "belongs to edition as optional" do
  association = Story.reflect_on_association(:edition)
  assert_equal :belongs_to, association.macro
  assert association.options[:optional]
end
```

---

## Info

### IN-01: `position` field has no fixture data and no test coverage

**File:** `test/fixtures/stories.yml` (absent); `test/models/story_test.rb` (absent)
**Issue:** `db/schema.rb` line 42 shows `t.integer "position"` on stories. The CLAUDE.md data model documents it as "ordering within the edition." No fixture sets a `position` value, and no test exercises ordering behavior. This is an informational gap — the column is nullable so fixtures are valid — but any ordering scope or default scope on `position` added to the model would be completely untested.

**Fix:** Add `position` values to the story fixtures and, when ordering logic is added to the model, add a corresponding test.

---

### IN-02: `.rubocop.yml` excludes all fixture YAML files globally rather than narrowly

**File:** `.rubocop.yml:5`
**Issue:** The `Exclude` pattern `"test/fixtures/**/*.yml"` opts all fixture files out of RuboCop entirely. RuboCop's YAML cop (`Lint/Syntax`) does not apply to `.yml` files by default anyway, so this exclusion has no practical effect — but it signals intent that may mislead future contributors into thinking fixtures are linted and then deliberately excluded for a reason. The comment block below the exclusion (lines 9–13) is commented-out sample config, which adds noise.

**Fix:** Remove the `AllCops.Exclude` block for fixture YAML (it is a no-op) or add an explanatory comment clarifying the intent. Remove or uncomment the dead sample config lines.

---

_Reviewed: 2026-05-10T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
