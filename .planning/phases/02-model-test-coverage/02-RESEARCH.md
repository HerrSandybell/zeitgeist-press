# Phase 2: Model Test Coverage - Research

**Researched:** 2026-05-10
**Domain:** Rails 8.1 Minitest model testing — validations, enums, associations
**Confidence:** HIGH

---

## Summary

Phase 2 replaces three empty scaffold test stubs with real Minitest tests covering the three domain models: Newspaper, Edition, and Story. All models already exist and have all migrations applied. The test infrastructure (test_helper.rb, fixtures, parallelization config) is already wired up by Rails. The only work is writing test bodies and updating YAML fixtures to be semantically meaningful.

The main decision surface is how to test enums and associations — both have multiple valid Minitest idioms, and this research identifies the ones that best match this project's conventions (thin, no mocking, no DSL gems). The key gotcha is that Rails enums raise `ArgumentError` (not a validation error) for invalid values, which changes how those tests must be structured.

The fixtures currently contain scaffold-generated placeholder data (season: 1, story_type: 1, MyString). They are usable as-is but would benefit from being updated to use labeled enum values (season: spring) and meaningful strings, both for readability and to ensure the fixture loader exercises the string-to-integer mapping path.

**Primary recommendation:** Write inline `test "..." do` blocks directly in the existing test files. Update fixtures to use enum label strings. Use `assert_predicate`, `refute_valid`, and `assert_raises ArgumentError` for the three test categories.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Newspaper model tests cover name presence validation and has_many :editions association | Model confirmed: `validates :name, presence: true` and `has_many :editions, dependent: :destroy`. Test via `assert_not` on invalid record + `reflect_on_association`. |
| TEST-02 | Edition model tests cover season enum values, day numericality (1–90), year/season/day/volume/issue_number presence, and published flag default | All verified via `rails runner`: four season values, `validates :day, numericality: { in: 1..90 }`, five presence validations, `published` DB default is `false`. |
| TEST-03 | Story model tests cover story_type enum values, optional edition association (edition_id nullable), and story_type/headline/body presence validations | All verified via `rails runner`: four story_type values, `belongs_to :edition, optional: true`, column `edition_id` is nullable in schema, three presence validations. |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Validation logic | Model (ActiveRecord) | — | Validations live in model classes; tests invoke model methods directly |
| Enum integrity | Model (ActiveRecord) | Database (integer column) | Rails enum maps string labels to DB integers; tests cover both the labels and the mapping |
| Association structure | Model (ActiveRecord) | — | `reflect_on_association` introspects model metadata; no DB queries needed |
| Test data setup | Fixtures (YAML) | — | `fixtures :all` loads from `test/fixtures/*.yml`; all three fixture files exist |
| Test execution | Minitest runner | — | `rails test` invokes minitest; parallelization enabled above 50 tests (won't trigger here) |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Minitest | 6.0.6 | Test runner, assertions, test case base class | Project constraint; already in Gemfile.lock; built into Rails |
| ActiveSupport::TestCase | (Rails 8.1.3) | Base class for model tests; loads fixtures, provides `assert_*` helpers | All three test files already inherit from it |
| YAML Fixtures | (built-in) | Test data; loaded via `fixtures :all` in test_helper.rb | Project constraint; fixture files already exist for all three models |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Rails runner | (Rails 8.1.3) | One-off verification of model behavior | Used during research; not in tests |
| RuboCop (rubocop-rails-omakase) | 1.86.1 | Style enforcement | Run after writing tests to ensure style compliance |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| YAML fixtures | FactoryBot | FactoryBot is explicitly out of scope per project constraint |
| ActiveSupport::TestCase | RSpec | RSpec is explicitly out of scope per project constraint |
| `assert_raises ArgumentError` | `assert_invalid` on enum | Rails enums raise ArgumentError before validation runs; custom validation matchers would be wrong here |

No installation required — all dependencies are already present.

---

## Architecture Patterns

### System Architecture Diagram

```
test/models/*_test.rb
       |
       | inherits
       v
ActiveSupport::TestCase  <--  fixtures :all (test_helper.rb)
       |                              |
       | calls                        | loads
       v                              v
  Model class              test/fixtures/*.yml
  (Newspaper,              (newspapers.yml,
   Edition,                 editions.yml,
   Story)                   stories.yml)
       |
       | validates / raises / reflects
       v
  ActiveRecord layer
  (validations, enums, associations)
       |
       v
  SQLite test DB
```

### Recommended Project Structure

No new directories or files needed. The three existing test files are extended in place.

```
test/
├── fixtures/
│   ├── newspapers.yml      # Update from scaffold placeholders to semantic data
│   ├── editions.yml        # Update: use enum labels, add published field
│   └── stories.yml         # Update: use enum labels, add orphan story fixture
└── models/
    ├── newspaper_test.rb   # Replace commented stub with real tests
    ├── edition_test.rb     # Replace commented stub with real tests
    └── story_test.rb       # Replace commented stub with real tests
```

### Pattern 1: Presence Validation Test

**What:** Assert that a model with a missing required field is invalid, and that the error is on the expected attribute.
**When to use:** For every `validates :field, presence: true` declaration.

```ruby
# Source: Rails Minitest conventions / verified against running test suite
test "is invalid without name" do
  newspaper = Newspaper.new(name: nil)
  assert_not newspaper.valid?
  assert_includes newspaper.errors[:name], "can't be blank"
end
```

### Pattern 2: Enum Values Test

**What:** Assert that all expected enum labels are defined and map to the correct integer values.
**When to use:** For every `enum` declaration on a model.

```ruby
# Source: verified via rails runner against Edition and Story models
test "season enum defines all four values" do
  assert_equal({ "spring" => 0, "summer" => 1, "autumn" => 2, "winter" => 3 }, Edition.seasons)
end

test "invalid season raises ArgumentError" do
  assert_raises(ArgumentError) { Edition.new(season: :invalid_season) }
end
```

Note: Rails enums raise `ArgumentError` immediately when an invalid value is assigned — this happens before `valid?` is called. Tests for invalid enum values must use `assert_raises`, not `assert_not record.valid?`. [VERIFIED: rails runner]

### Pattern 3: Numericality Validation Test

**What:** Assert that boundary values at and beyond the allowed range are handled correctly.
**When to use:** For `validates :field, numericality: { in: range }`.

```ruby
# Source: verified via rails runner — day: 91 produces "must be in 1..90"
test "is invalid with day outside 1-90" do
  edition = editions(:one)
  edition.day = 91
  assert_not edition.valid?
  assert_includes edition.errors[:day], "must be in 1..90"

  edition.day = 0
  assert_not edition.valid?
end

test "is valid with day at boundary values" do
  edition = editions(:one)
  edition.day = 1
  assert_predicate edition, :valid?

  edition.day = 90
  assert_predicate edition, :valid?
end
```

### Pattern 4: Boolean Default Test

**What:** Assert that a new (unsaved) record has the expected default value for a boolean attribute.
**When to use:** For columns with DB-level defaults.

```ruby
# Source: verified via rails runner — Edition.new.published == false
test "published defaults to false" do
  edition = Edition.new
  assert_equal false, edition.published
end
```

### Pattern 5: Association Test via Reflection

**What:** Assert that the model declares the expected association.
**When to use:** For `has_many`, `belongs_to` declarations. Reflection tests the structural declaration without requiring live records.

```ruby
# Source: verified via rails runner — Newspaper.reflect_on_association(:editions).macro == :has_many
test "has many editions" do
  association = Newspaper.reflect_on_association(:editions)
  assert_equal :has_many, association.macro
end
```

### Pattern 6: Optional Association Test (nullable FK)

**What:** Assert that a model with a nil FK is still valid.
**When to use:** For `belongs_to :model, optional: true`.

```ruby
# Source: verified via rails runner — Story.new(story_type: :major, headline: 'h', body: 'b').valid? == true
test "is valid without an edition" do
  story = Story.new(story_type: :major, headline: "A Headline", body: "Body text.")
  assert_predicate story, :valid?
end
```

### Anti-Patterns to Avoid

- **Testing via `assert_equal false, record.valid?`:** Prefer `assert_not record.valid?` — more idiomatic Minitest.
- **Using `assert_raises` for presence validation failures:** Presence validations do not raise; they populate `record.errors`. `assert_raises` is only correct for invalid enum value assignment.
- **Using integer literals in fixture season/story_type fields:** The scaffold fixtures use `season: 1`, `story_type: 1`. While Rails accepts integer values in fixtures, using label strings (`season: spring`, `story_type: secondary`) is more readable and exercises the label-to-integer path. Update the fixtures.
- **Skipping the fixture `published` field:** The `editions.yml` scaffold does not include `published`. Since the DB default is `false`, the fixture will load correctly without it, but adding `published: false` (or `published: true` for a "published edition" fixture) makes intent explicit.
- **Building records from scratch in every test instead of using fixtures:** For tests that need a valid record as a starting point (e.g., to then make one field invalid), load a fixture and mutate it — fewer setup lines.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test data setup | Factory helpers or `before` blocks that call `Model.create!` | YAML fixtures + fixture accessor | Fixtures are faster (loaded once per suite), already required by `test_helper.rb`, and the project constraint mandates them |
| Enum exhaustiveness check | Manual array comparison | `Model.enum_values_hash` assertion (e.g., `assert_equal({...}, Edition.seasons)`) | The hash is the authoritative source; comparing against it catches both missing and spurious values |
| Association structure check | Loading a parent record and calling a scope | `reflect_on_association` | No DB query; purely structural check |

**Key insight:** Minitest + fixtures is a lower-ceremony stack than RSpec + FactoryBot. The right instinct is to write fewer lines of setup, not more.

---

## Common Pitfalls

### Pitfall 1: Invalid Enum Value Doesn't Fail `valid?`

**What goes wrong:** A test tries `record = Model.new(enum_field: :bad_value); assert_not record.valid?` — the test itself raises `ArgumentError` and the suite errors, not fails.
**Why it happens:** Rails `enum` validates at assignment time via `ArgumentError`, not at `valid?` call time.
**How to avoid:** Use `assert_raises(ArgumentError) { Model.new(enum_field: :bad_value) }` for invalid enum value tests.
**Warning signs:** `Error: ArgumentError: 'bad_value' is not a valid ...` in the test output instead of a failure.

### Pitfall 2: Fixture Edition Missing `published` Column

**What goes wrong:** The scaffold `editions.yml` does not include a `published` field. If a test depends on `published` being explicitly set, the fixture won't provide it. The DB default (`false`) applies, so it silently works — but intent is unclear.
**Why it happens:** The `add_published_to_editions` migration was applied after the scaffold generated the fixture.
**How to avoid:** Add `published: false` to both existing edition fixtures. Add a second fixture with `published: true` if testing published-state logic.
**Warning signs:** Tests that check `published` state pass on coincidence rather than explicit fixture data.

### Pitfall 3: Story Fixture Has `edition_id` Hardwired

**What goes wrong:** The scaffold `stories.yml` assigns `edition: one` and `edition: two`. This means no existing fixture represents an orphan story (edition_id = nil). Testing "valid without an edition" requires building a record in-test rather than loading a fixture.
**Why it happens:** The scaffold generated the fixture before `make_edition_optional_on_stories` was applied.
**How to avoid:** Add a third fixture entry (e.g., `orphan`) with no `edition:` key. Use it in the nullable association test.
**Warning signs:** Test builds a `Story.new(...)` from scratch when it could use a fixture — this is fine, but adding the orphan fixture makes the fixture set complete.

### Pitfall 4: Parallelization and Fixture Transactions

**What goes wrong:** With `parallelize(workers: :number_of_processors)` enabled in test_helper.rb, fixture transactions can conflict if tests share mutable state.
**Why it happens:** The threshold is 50 tests. Phase 2 will have far fewer than 50 tests, so parallelization will NOT activate. This is a non-issue for this phase.
**Warning signs:** Flaky test failures only when running the full suite. Not expected here.

### Pitfall 5: RuboCop Omakase Style on Test Files

**What goes wrong:** The rubocop-rails-omakase ruleset enforces specific conventions. Common violations in test files: double-quoted string preference, trailing whitespace, line length.
**Why it happens:** The project uses `rubocop-rails-omakase` with no overrides.
**How to avoid:** Run `bin/rubocop test/models/` after writing each test file. Fix before committing.
**Warning signs:** `bin/ci` or `bin/rubocop` fails after the test files are added.

---

## Code Examples

Verified patterns from live model introspection:

### Confirmed Enum Hashes

```ruby
# Source: verified via rails runner 2026-05-10
Edition.seasons   # => {"spring"=>0, "summer"=>1, "autumn"=>2, "winter"=>3}
Story.story_types # => {"major"=>0, "secondary"=>1, "tertiary"=>2, "advertisement"=>3}
```

### Confirmed Validations

```ruby
# Newspaper
validates :name, presence: true

# Edition
validates :year, :season, :day, :volume, :issue_number, presence: true
validates :day, numericality: { in: 1..90 }

# Story
validates :story_type, :headline, :body, presence: true
belongs_to :edition, optional: true
```

### Confirmed Schema Facts

```ruby
# editions.published — DB default false, not null
# stories.edition_id — nullable (null: true in schema after migration)
# Newspaper.reflect_on_association(:editions).macro  => :has_many
# Newspaper.reflect_on_association(:editions).options => { dependent: :destroy }
# Story.reflect_on_association(:edition).options     => { optional: true }
```

### Fixture Label String Syntax (Rails 8.1)

```yaml
# editions.yml — use label strings for enum fields
one:
  newspaper: one
  year: 2025
  season: spring       # label string, not integer 0
  day: 45
  volume: 1
  issue_number: 1
  published: false

published_one:
  newspaper: one
  year: 2025
  season: summer
  day: 12
  volume: 1
  issue_number: 2
  published: true
```

```yaml
# stories.yml — add orphan fixture with no edition
orphan:
  story_type: major    # label string, not integer 0
  headline: An Orphaned Story
  body: This story has no edition yet.
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Integer-based enum fixture values (`season: 1`) | Label string values (`season: spring`) | Rails 4.1+ enum + fixture string support | Fixtures are more readable; string values map through the enum dictionary |
| `assert_equal false, record.valid?` | `assert_not record.valid?` or `refute record.valid?` | Minitest convention | Clearer failure message |
| Custom `validates_inclusion_of :season, in: %w[spring ...]` | Native `enum :season, { ... }` | Rails 7+ keyword enum syntax | Enum raises on bad assignment; `validates_inclusion_of` is no longer standard |

**Deprecated/outdated:**
- `enum season: { spring: 0, ... }` (hash rocket syntax): Still works but Rails 7+ prefers `enum :season, { ... }` (keyword syntax). The project uses the keyword syntax already.
- `assert_equal false, record.valid?`: Functional but not idiomatic. Prefer `assert_not`.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Ruby | All tests | Yes | 3.3.5 | — |
| Rails / Minitest | Test runner | Yes | 8.1.3 / 6.0.6 | — |
| SQLite (test DB) | Fixture loading | Yes | (via sqlite3 gem 2.9.4) | — |
| RuboCop | Style check post-write | Yes | 1.86.1 | Skip style pass (not recommended) |

No missing dependencies. All tools required for this phase are available.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Fixture label strings for enum fields (e.g., `season: spring`) work in Rails 8.1 YAML fixtures | Code Examples | If Rails requires integer values in fixtures, the fixture load would fail — low risk, this has worked since Rails 4.1 |

All other claims were verified via direct `rails runner` invocation against the live codebase.

---

## Open Questions

1. **Whether to assert `dependent: :destroy` on the Newspaper `has_many :editions` association**
   - What we know: `reflect_on_association(:editions).options` returns `{ dependent: :destroy }` [VERIFIED]
   - What's unclear: TEST-01 says "tests cover... has_many :editions association" but doesn't specify how deep — structural check (reflection) vs behavioral check (destroy cascades)
   - Recommendation: Structural reflection check is sufficient for this phase. A behavioral cascade test would require creating and destroying live records via fixtures, which adds complexity not required by the success criteria.

2. **Whether to test the `belongs_to :newspaper` on Edition**
   - What we know: Edition has `belongs_to :newspaper` (null: false in DB) but TEST-02 does not list this association in its coverage requirements
   - What's unclear: Should the test assert this, or only the items listed in the requirement?
   - Recommendation: Skip — TEST-02 does not require it, and adding untargeted tests risks scope creep.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on Phase |
|-----------|-----------------|
| Minitest + YAML fixtures ONLY — no RSpec, no FactoryBot | All test data via fixtures; no `let`, `describe`, `subject`, `create` helpers |
| No unnecessary comments | Test names must be self-documenting; no inline comment annotations |
| Keep changes minimal and focused | No test for associations or behaviors not listed in TEST-01/02/03 |
| Prefer editing existing files over creating new ones | Extend the three existing test files; do not create a shared support module |
| Validate only at system boundaries | Model unit tests are correct here; no need for integration or system tests in this phase |

---

## Sources

### Primary (HIGH confidence)
- Direct `bundle exec rails runner` invocations against the live codebase — model introspection, enum hashes, validation error messages, column nullability, association macros and options. All findings confirmed against Rails 8.1.3 / Ruby 3.3.5.
- `db/schema.rb` — authoritative column definitions, nullability, defaults
- `app/models/*.rb` — authoritative validation and enum declarations
- `test/test_helper.rb` — confirms `fixtures :all` and parallelization threshold
- `test/fixtures/*.yml` — confirms scaffold placeholder data in all three fixture files

### Secondary (MEDIUM confidence)
- Rails 8.1 Minitest conventions for `assert_raises ArgumentError` on enum assignment — consistent with Rails enum implementation across 7.x and 8.x

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools verified present in running environment
- Architecture: HIGH — all model declarations and schema facts verified via live introspection
- Pitfalls: HIGH — ArgumentError behavior verified via rails runner; other pitfalls verified from schema diffs
- Fixture patterns: HIGH — scaffold YAML inspected directly; enum label string syntax verified for this Rails version

**Research date:** 2026-05-10
**Valid until:** 2026-06-10 (stable — no external services, no version-sensitive APIs)
