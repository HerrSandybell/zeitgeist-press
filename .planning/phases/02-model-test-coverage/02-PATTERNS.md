# Phase 2: Model Test Coverage - Pattern Map

**Mapped:** 2026-05-10
**Files analyzed:** 6 (3 test files, 3 fixture files)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/models/newspaper_test.rb` | test | request-response | `test/models/edition_test.rb` (scaffold shell) + `app/models/newspaper.rb` | role-match |
| `test/models/edition_test.rb` | test | request-response | `test/models/newspaper_test.rb` (scaffold shell) + `app/models/edition.rb` | role-match |
| `test/models/story_test.rb` | test | request-response | `test/models/newspaper_test.rb` (scaffold shell) + `app/models/story.rb` | role-match |
| `test/fixtures/newspapers.yml` | config | batch | `test/fixtures/editions.yml` (scaffold data) | role-match |
| `test/fixtures/editions.yml` | config | batch | `test/fixtures/stories.yml` (scaffold data) | role-match |
| `test/fixtures/stories.yml` | config | batch | `test/fixtures/editions.yml` (scaffold data) | role-match |

---

## Pattern Assignments

### `test/models/newspaper_test.rb` (test, request-response)

**Analog:** `test/test_helper.rb` (base class wiring) + `app/models/newspaper.rb` (declarations under test)

**File shell pattern** (`test/models/newspaper_test.rb` lines 1-7 — current state to replace body of):
```ruby
require "test_helper"

class NewspaperTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
```

**Base class wiring** (`test/test_helper.rb` lines 1-15):
```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end
```
Note: `fixtures :all` loads all YAML files in `test/fixtures/`. Fixture accessor methods (`newspapers(:one)`) are available in every test method automatically.

**Model declarations being tested** (`app/models/newspaper.rb` lines 1-5):
```ruby
class Newspaper < ApplicationRecord
  has_many :editions, dependent: :destroy

  validates :name, presence: true
end
```

**Presence validation test pattern** (from RESEARCH.md Pattern 1):
```ruby
test "is invalid without name" do
  newspaper = Newspaper.new(name: nil)
  assert_not newspaper.valid?
  assert_includes newspaper.errors[:name], "can't be blank"
end
```

**Association reflection test pattern** (from RESEARCH.md Pattern 5):
```ruby
test "has many editions" do
  association = Newspaper.reflect_on_association(:editions)
  assert_equal :has_many, association.macro
end
```
Use `reflect_on_association` — no DB query needed, purely structural check.

---

### `test/models/edition_test.rb` (test, request-response)

**Analog:** `test/test_helper.rb` + `app/models/edition.rb`

**Model declarations being tested** (`app/models/edition.rb` lines 1-9):
```ruby
class Edition < ApplicationRecord
  belongs_to :newspaper
  has_many :stories, dependent: :destroy

  enum :season, { spring: 0, summer: 1, autumn: 2, winter: 3 }

  validates :year, :season, :day, :volume, :issue_number, presence: true
  validates :day, numericality: { in: 1..90 }
end
```

**Enum values test pattern** (from RESEARCH.md Pattern 2):
```ruby
test "season enum defines all four values" do
  assert_equal({ "spring" => 0, "summer" => 1, "autumn" => 2, "winter" => 3 }, Edition.seasons)
end

test "invalid season raises ArgumentError" do
  assert_raises(ArgumentError) { Edition.new(season: :invalid_season) }
end
```
Critical: Rails enum raises `ArgumentError` at assignment time, before `valid?` runs. Do NOT use `assert_not record.valid?` for invalid enum values — it will itself raise and error the suite.

**Numericality test pattern** (from RESEARCH.md Pattern 3):
```ruby
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
Load fixture then mutate one field — fewer setup lines than `Edition.new(all: fields)`.

**Boolean default test pattern** (from RESEARCH.md Pattern 4):
```ruby
test "published defaults to false" do
  edition = Edition.new
  assert_equal false, edition.published
end
```
Confirmed by schema: `t.boolean "published", default: false, null: false`.

**Presence validation pattern** (repeat of Pattern 1 per field):
```ruby
test "is invalid without year" do
  edition = editions(:one)
  edition.year = nil
  assert_not edition.valid?
  assert_includes edition.errors[:year], "can't be blank"
end
```
Apply this structure for each of: `year`, `season`, `day`, `volume`, `issue_number`.

---

### `test/models/story_test.rb` (test, request-response)

**Analog:** `test/test_helper.rb` + `app/models/story.rb`

**Model declarations being tested** (`app/models/story.rb` lines 1-7):
```ruby
class Story < ApplicationRecord
  belongs_to :edition, optional: true

  enum :story_type, { major: 0, secondary: 1, tertiary: 2, advertisement: 3 }

  validates :story_type, :headline, :body, presence: true
end
```

**Enum values test pattern** (same structure as Edition — from RESEARCH.md Pattern 2):
```ruby
test "story_type enum defines all four values" do
  assert_equal({ "major" => 0, "secondary" => 1, "tertiary" => 2, "advertisement" => 3 }, Story.story_types)
end

test "invalid story_type raises ArgumentError" do
  assert_raises(ArgumentError) { Story.new(story_type: :invalid_type) }
end
```

**Optional association test pattern** (from RESEARCH.md Pattern 6):
```ruby
test "is valid without an edition" do
  story = Story.new(story_type: :major, headline: "A Headline", body: "Body text.")
  assert_predicate story, :valid?
end
```
Confirmed by schema: `t.integer "edition_id"` (no `null: false`), and `belongs_to :edition, optional: true` in model.

**Presence validation pattern** (same structure as Newspaper/Edition):
```ruby
test "is invalid without headline" do
  story = stories(:one)
  story.headline = nil
  assert_not story.valid?
  assert_includes story.errors[:headline], "can't be blank"
end
```
Apply for each of: `story_type`, `headline`, `body`.

---

### `test/fixtures/newspapers.yml` (config, batch)

**Analog:** Current scaffold content (lines 1-7 — replace `MyString` with meaningful names):
```yaml
# Read about fixtures at https://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html

one:
  name: MyString

two:
  name: MyString
```

**Target pattern** — use meaningful string values:
```yaml
one:
  name: The Daily Chronicle

two:
  name: The Evening Post
```
No other columns exist on `newspapers` (`created_at`/`updated_at` are auto-managed).

---

### `test/fixtures/editions.yml` (config, batch)

**Analog:** Current scaffold content (lines 1-20 — three changes needed):

Current state (`test/fixtures/editions.yml` lines 1-20):
```yaml
one:
  newspaper: one
  year: 1
  season: 1      # integer — must become label string
  day: 1
  volume: 1
  issue_number: 1
  attention_bar: MyString
               # published field is missing — must be added
```

**Target pattern** — label strings for enum, add `published`, add second fixture for published state, use realistic values:
```yaml
one:
  newspaper: one
  year: 2025
  season: spring
  day: 45
  volume: 1
  issue_number: 1
  published: false

two:
  newspaper: two
  year: 2025
  season: autumn
  day: 12
  volume: 2
  issue_number: 3
  published: true
```
Drop `attention_bar: MyString` (nullable string column, not required by any validation — omitting it keeps fixtures lean). Use enum label strings (`season: spring`) not integers (`season: 1`). Add `published:` explicitly so intent is clear rather than relying on the DB default silently.

---

### `test/fixtures/stories.yml` (config, batch)

**Analog:** Current scaffold content (lines 1-28 — two changes needed):

Current state (`test/fixtures/stories.yml` lines 1-28):
```yaml
one:
  edition: one
  story_type: 1    # integer — must become label string
  position: 1
  headline: MyString
  body: MyText
  supertitle: MyString
  subtitle: MyString
  author: MyString
  quote: MyText
  quote_origin: MyString
  summary_ticker: MyString
```

**Target pattern** — label strings for enum, trim optional columns, add orphan fixture:
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
The `orphan` fixture has no `edition:` key — this leaves `edition_id` as NULL, exercising the nullable FK path. The optional columns (`position`, `supertitle`, `subtitle`, `author`, `quote`, `quote_origin`, `summary_ticker`) are all nullable and not required by any validation — omit them for cleaner fixtures.

---

## Shared Patterns

### Test File Shell
**Source:** All three current scaffold test stubs (`test/models/*_test.rb` lines 1-7)
**Apply to:** All three test files — keep `require "test_helper"` and `< ActiveSupport::TestCase` unchanged; only replace the commented stub body.
```ruby
require "test_helper"

class XxxTest < ActiveSupport::TestCase
  # tests go here
end
```

### Fixture Accessor Pattern
**Source:** `test/test_helper.rb` line 11 (`fixtures :all`)
**Apply to:** All test files that reference fixture records
```ruby
# Inside any test method, access fixtures via:
newspapers(:one)   # returns the Newspaper record for fixture "one"
editions(:one)     # returns the Edition record for fixture "one"
stories(:orphan)   # returns the Story record for fixture "orphan"
```
These are automatically available because `fixtures :all` is set in `test_helper.rb`.

### Presence Validation Pattern
**Source:** RESEARCH.md Pattern 1 (verified against live models)
**Apply to:** Every `validates :field, presence: true` — newspaper `name`, edition `year/season/day/volume/issue_number`, story `story_type/headline/body`
```ruby
test "is invalid without FIELD" do
  record = model_fixture(:one)
  record.field = nil
  assert_not record.valid?
  assert_includes record.errors[:field], "can't be blank"
end
```

### Enum ArgumentError Pattern
**Source:** RESEARCH.md Pattern 2 (verified via rails runner)
**Apply to:** `edition_test.rb` (season enum), `story_test.rb` (story_type enum)
```ruby
test "invalid ENUM raises ArgumentError" do
  assert_raises(ArgumentError) { Model.new(enum_field: :invalid_value) }
end
```
This is the only correct pattern for invalid enum assignment — `assert_not record.valid?` will itself raise and error the suite.

### assert_predicate vs assert_not
**Apply to:** All test files
- Use `assert_predicate record, :valid?` when asserting a record IS valid
- Use `assert_not record.valid?` when asserting a record is NOT valid
- Never use `assert_equal false, record.valid?` (functional but not idiomatic)

---

## No Analog Found

All six files have close analogs in the codebase. No files in this phase require falling back to RESEARCH.md patterns exclusively.

---

## Metadata

**Analog search scope:** `test/`, `app/models/`, `db/schema.rb`
**Files scanned:** 10 (`newspaper.rb`, `edition.rb`, `story.rb`, `test_helper.rb`, `newspaper_test.rb`, `edition_test.rb`, `story_test.rb`, `newspapers.yml`, `editions.yml`, `stories.yml`, `schema.rb`)
**Pattern extraction date:** 2026-05-10
