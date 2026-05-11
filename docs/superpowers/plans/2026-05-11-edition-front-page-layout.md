# Phase 3b — Edition Front Page Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Render the edition show page as a real newspaper front page — masthead, attention bar, and a tetris-packed CSS Grid of typed story slots — replacing the current vertical list of headlines and paragraphs.

**Architecture:** Two view partials (`_masthead`, `_story`) feed a 4-column CSS Grid container. Grid uses `grid-auto-flow: row dense` so variable story counts pack cleanly. Per-newspaper themes own the layout dimensions (column count, row unit, story spans) — Pryce of Progress gets full-width majors, half-width secondaries, tall single-column tertiaries, and square advertisements. Stories order by `story_type` (the enum value already encodes visual hierarchy).

**Tech Stack:** Rails 8.1, ERB partials, vanilla CSS Grid with custom properties, Minitest.

**Reference spec:** `docs/superpowers/specs/2026-05-10-design-system-edition-view-design.md` (sections: Edition Front Page Layout, Rails Views, Story Scopes)

**Prerequisite:** Phase 3a (design system foundation) is merged to main.

---

## File Map

- Modify: `app/models/story.rb` — add four `story_type` scopes
- Modify: `test/models/story_test.rb` — scope tests
- Modify: `test/fixtures/stories.yml` — add tertiary + advertisement fixtures so the controller test has all four types
- Modify: `app/controllers/editions_controller.rb` — order by `story_type` instead of `position`
- Create: `test/controllers/editions_controller_test.rb` — verify ordering + render
- Create: `app/views/editions/_masthead.html.erb` — masthead + attention bar partial
- Create: `app/views/editions/_story.html.erb` — story partial (handles all four story types)
- Modify: `app/views/editions/show.html.erb` — render partials inside a `.front-page-grid` container
- Create: `app/assets/stylesheets/base/grid.css` — `.front-page-grid` container (theme-overridable)
- Create: `app/assets/stylesheets/components/story.css` — story wrapper, type modifiers, subtitle/ticker/quote typography, `.headline--advertisement`
- Create: `app/assets/stylesheets/components/masthead.css` — masthead container layout
- Modify: `app/assets/stylesheets/themes/pryce_of_progress.css` — add `--grid-row-unit` and story slot spans

Propshaft auto-includes every CSS file in `app/assets/stylesheets/`, so new CSS files load automatically without touching `application.css`.

---

### Task 1: Add Story scopes with tests

**Files:**
- Modify: `app/models/story.rb`
- Modify: `test/models/story_test.rb`
- Modify: `test/fixtures/stories.yml`

- [ ] **Step 1: Add tertiary and advertisement fixtures to `test/fixtures/stories.yml`**

The existing fixtures only cover `major` (one, orphan) and `secondary` (two). To test scopes properly and to give Task 2's controller test all four types in one edition, we need fixtures for tertiary and advertisement attached to edition `one`.

Append to `test/fixtures/stories.yml`:

```yaml
tertiary_one:
  edition: one
  story_type: tertiary
  headline: A Tertiary Item
  body: The full text of a tertiary story.

ad_one:
  edition: one
  story_type: advertisement
  headline: Wares For Sale
  body: One slightly used cabinet, no questions.

secondary_one:
  edition: one
  story_type: secondary
  headline: Inside Edition One
  body: Secondary story for edition one.
```

- [ ] **Step 2: Add failing scope tests to `test/models/story_test.rb`**

Append these tests inside the `StoryTest` class, before the final `end`:

```ruby
  test "major scope returns only major stories" do
    assert_equal Story.where(story_type: :major).sort, Story.major.sort
    assert Story.major.all? { |s| s.major? }
  end

  test "secondary scope returns only secondary stories" do
    assert_equal Story.where(story_type: :secondary).sort, Story.secondary.sort
    assert Story.secondary.all? { |s| s.secondary? }
  end

  test "tertiary scope returns only tertiary stories" do
    assert_equal Story.where(story_type: :tertiary).sort, Story.tertiary.sort
    assert Story.tertiary.all? { |s| s.tertiary? }
  end

  test "advertisement scope returns only advertisement stories" do
    assert_equal Story.where(story_type: :advertisement).sort, Story.advertisement.sort
    assert Story.advertisement.all? { |s| s.advertisement? }
  end
```

- [ ] **Step 3: Run the tests — expect failures**

```bash
bin/rails test test/models/story_test.rb
```

Expected: 4 errors with `NoMethodError: undefined method 'major' for Story` (or similar). The seven existing tests should still pass.

- [ ] **Step 4: Add the scopes to `app/models/story.rb`**

```ruby
class Story < ApplicationRecord
  belongs_to :edition, optional: true

  enum :story_type, { major: 0, secondary: 1, tertiary: 2, advertisement: 3 }

  validates :story_type, :headline, :body, presence: true

  scope :major,         -> { where(story_type: :major) }
  scope :secondary,     -> { where(story_type: :secondary) }
  scope :tertiary,      -> { where(story_type: :tertiary) }
  scope :advertisement, -> { where(story_type: :advertisement) }
end
```

- [ ] **Step 5: Run the tests — expect pass**

```bash
bin/rails test test/models/story_test.rb
```

Expected: `11 runs, ... 0 failures, 0 errors, 0 skips`.

- [ ] **Step 6: Commit**

```bash
git add app/models/story.rb test/models/story_test.rb test/fixtures/stories.yml
git commit -m "feat(model): add Story scopes per story_type"
```

---

### Task 2: Order stories by type in EditionsController

**Files:**
- Modify: `app/controllers/editions_controller.rb`
- Create: `test/controllers/editions_controller_test.rb`

The controller currently orders stories by `position`. The spec drops `position` from rendering — `story_type` already encodes visual hierarchy (major: 0, secondary: 1, tertiary: 2, advertisement: 3).

- [ ] **Step 1: Write the failing controller test**

Create `test/controllers/editions_controller_test.rb`:

```ruby
require "test_helper"

class EditionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @edition = editions(:one)
    @newspaper = @edition.newspaper
  end

  test "show responds with 200" do
    get newspaper_edition_url(@newspaper, @edition)
    assert_response :success
  end

  test "show renders all stories for the edition" do
    get newspaper_edition_url(@newspaper, @edition)
    @edition.stories.each do |story|
      assert_includes response.body, story.headline,
        "Expected response to include headline #{story.headline.inspect}"
    end
  end

  test "show renders stories ordered by story_type ascending" do
    get newspaper_edition_url(@newspaper, @edition)
    major         = stories(:one)
    secondary     = stories(:secondary_one)
    tertiary      = stories(:tertiary_one)
    advertisement = stories(:ad_one)

    positions = [major, secondary, tertiary, advertisement].map do |s|
      response.body.index(s.headline)
    end
    assert positions.all?, "Expected all four headlines to appear in response body"
    assert_equal positions, positions.sort,
      "Expected story_type order: major < secondary < tertiary < advertisement"
  end
end
```

The test uses `response.body.index(headline)` instead of `assigns(:stories)` because Rails 8 integration tests do not expose `assigns` without the `rails-controller-testing` gem. Checking substring positions in the rendered HTML verifies the actual on-page order, which is what the user sees.

- [ ] **Step 2: Run the test — expect at least one failure**

```bash
bin/rails test test/controllers/editions_controller_test.rb
```

Expected: the order test may fail because the current controller uses `.order(:position)` and `position` defaults to `nil` for our fixtures — meaning the order is currently undefined. The success and "renders all stories" tests should pass.

- [ ] **Step 3: Update `app/controllers/editions_controller.rb`**

```ruby
class EditionsController < ApplicationController
  def show
    @edition = Edition.includes(:newspaper).find(params[:id])
    @stories = @edition.stories.order(:story_type)
  end
end
```

- [ ] **Step 4: Run the test — expect pass**

```bash
bin/rails test test/controllers/editions_controller_test.rb
```

Expected: `3 runs, 3 assertions, 0 failures, 0 errors, 0 skips`.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/editions_controller.rb test/controllers/editions_controller_test.rb
git commit -m "feat(controller): order edition stories by story_type"
```

---

### Task 3: Create the masthead partial

The masthead is the page header: newspaper name, edition label, and the optional attention bar. Extracting it into a partial keeps `show.html.erb` focused on layout structure.

**Files:**
- Create: `app/views/editions/_masthead.html.erb`
- Modify: `app/views/editions/show.html.erb`

- [ ] **Step 1: Create `app/views/editions/_masthead.html.erb`**

```erb
<%# locals: (edition:) %>
<header class="masthead">
  <h1 class="masthead-title"><%= edition.newspaper.name %></h1>
  <p class="masthead-subtitle"><%= edition.label %> · Vol. <%= edition.volume %>, No. <%= edition.issue_number %></p>

  <% if edition.attention_bar.present? %>
    <p class="attention-bar"><%= edition.attention_bar %></p>
  <% end %>
</header>
```

- [ ] **Step 2: Update `app/views/editions/show.html.erb` to render the partial**

Replace the existing `<h1>` and `<h2>` lines. The new file:

```erb
<%= render "masthead", edition: @edition %>

<% @stories.each do |story| %>
  <h3><%= story.headline %></h3>
  <p><%= story.body %></p>
<% end %>
```

(The story loop stays unchanged for now — Task 4 replaces it.)

- [ ] **Step 3: Verify in the browser**

```bash
bin/dev
```

Open `http://localhost:3000/newspapers/1/editions/1`. Expected:
- Masthead shows "Pryce of Progress" in Rye (masthead font)
- Subtitle shows "10th of Spring, 501 · Vol. 2, No. 98"
- Attention bar shows the long banner with diamonds (accent color, bordered top and bottom)

Stop the dev server (Ctrl+C).

- [ ] **Step 4: Run the test suite**

```bash
bin/rails test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/views/editions/_masthead.html.erb app/views/editions/show.html.erb
git commit -m "feat(view): extract masthead partial for edition show"
```

---

### Task 4: Create the story partial

Single partial handles all four story types. Optional fields (supertitle, subtitle, summary_ticker, author, quote, quote_origin) render only when present. The wrapper element carries a type-specific class (`.story--major`, `.story--advertisement`, etc.) so CSS can style each variant.

`simple_format` is a Rails helper that converts `\n\n` (paragraph breaks in seed data bodies) to `<p>` tags.

**Files:**
- Create: `app/views/editions/_story.html.erb`
- Modify: `app/views/editions/show.html.erb`

- [ ] **Step 1: Create `app/views/editions/_story.html.erb`**

```erb
<%# locals: (story:) %>
<article class="story story--<%= story.story_type %>">
  <% if story.supertitle.present? %>
    <p class="story-supertitle"><%= story.supertitle %></p>
  <% end %>

  <h2 class="headline headline--<%= story.story_type %>"><%= story.headline %></h2>

  <% if story.subtitle.present? %>
    <p class="story-subtitle"><%= story.subtitle %></p>
  <% end %>

  <% if story.summary_ticker.present? %>
    <p class="story-ticker"><%= story.summary_ticker %></p>
  <% end %>

  <% if story.author.present? %>
    <p class="story-byline">By <%= story.author %></p>
  <% end %>

  <div class="story-body"><%= simple_format(story.body) %></div>

  <% if story.quote.present? %>
    <blockquote class="story-quote">
      <%= story.quote %>
      <% if story.quote_origin.present? %>
        <cite>— <%= story.quote_origin %></cite>
      <% end %>
    </blockquote>
  <% end %>
</article>
```

Optional fields use `.present?` directly — Active Record returns `nil` for unset attributes, and `nil.present?` is `false`, so unfilled fixtures and seed data with sparse fields both render cleanly.

- [ ] **Step 2: Update `app/views/editions/show.html.erb` to render the partial**

```erb
<%= render "masthead", edition: @edition %>

<% @stories.each do |story| %>
  <%= render "story", story: story %>
<% end %>
```

- [ ] **Step 3: Verify in the browser**

```bash
bin/dev
```

Open `http://localhost:3000/newspapers/1/editions/1`. Expected:
- Each story now shows its supertitle (uppercase, letter-spaced), headline, subtitle, summary ticker, byline, body (with proper paragraph breaks), and pull quote (where present)
- Major story shows the largest headline; advertisements show small headings
- All ad fields except headline and body collapse to nothing (no empty markup)
- Stories are still in a vertical column — the grid comes in Task 6

Stop the dev server.

- [ ] **Step 4: Run the test suite**

```bash
bin/rails test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add app/views/editions/_story.html.erb app/views/editions/show.html.erb
git commit -m "feat(view): extract shared story partial"
```

---

### Task 5: Add masthead and story component CSS

Now that the partials emit the right HTML structure, we style them. Base typography (`base/typography.css`) already handles the type-level rules (`.masthead-title`, `.attention-bar`, `.story-supertitle`, `.story-body`, `.story-byline`, `.headline--major/--secondary/--tertiary`). This task adds the structural component CSS that didn't fit in base typography — masthead spacing, story wrapper rules, the missing `.story-subtitle`, `.story-ticker`, `.story-quote`, and `.headline--advertisement` classes.

**Files:**
- Create: `app/assets/stylesheets/components/masthead.css`
- Create: `app/assets/stylesheets/components/story.css`

- [ ] **Step 1: Create `app/assets/stylesheets/components/masthead.css`**

```css
/*
 * Masthead component — the newspaper's page header.
 * Type rules for .masthead-title and .attention-bar live in base/typography.css.
 * This file adds spacing and the subtitle treatment.
 */

.masthead {
  padding: 2rem 1rem 1rem;
  text-align: center;
  border-bottom: calc(var(--rule-width) * 3) double var(--color-rule);
  margin-bottom: 1.5rem;
}

.masthead-subtitle {
  font-family: var(--font-body);
  font-style: italic;
  font-size: 1rem;
  color: var(--color-ink-muted);
  margin: 0 0 1rem;
}
```

- [ ] **Step 2: Create `app/assets/stylesheets/components/story.css`**

```css
/*
 * Story component — wrappers and field-level type for the _story partial.
 * Per-newspaper themes override .story--<type> column/row spans.
 */

.story {
  padding: 1rem;
  overflow: hidden;
  border-top: var(--rule-width) solid var(--color-rule);
}

.story-subtitle {
  font-family: var(--font-body);
  font-style: italic;
  font-size: 1.125rem;
  color: var(--color-ink-muted);
  margin: 0 0 0.75em;
}

.story-ticker {
  font-family: var(--font-headline);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-accent);
  margin: 0 0 0.75em;
}

.story-quote {
  font-family: var(--font-headline);
  font-size: 1.25rem;
  font-style: italic;
  border-left: calc(var(--rule-width) * 3) solid var(--color-accent);
  padding-left: 1rem;
  margin: 1em 0;
  color: var(--color-ink);
}

.story-quote cite {
  display: block;
  font-family: var(--font-body);
  font-style: normal;
  font-size: 0.875rem;
  color: var(--color-ink-muted);
  margin-top: 0.5em;
  letter-spacing: 0.05em;
}

.headline--advertisement {
  font-size: 1.125rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  text-align: center;
}

.story--advertisement {
  text-align: center;
  border: var(--rule-width) solid var(--color-rule);
  background-color: color-mix(in srgb, var(--color-paper) 92%, var(--color-ink) 8%);
}

.story--advertisement .story-body {
  text-align: center;
  font-size: 0.875rem;
}
```

- [ ] **Step 3: Verify in the browser**

```bash
bin/dev
```

Open `http://localhost:3000/newspapers/1/editions/1`. Expected:
- Masthead now has a triple-line double border below it
- Stories have top borders separating them
- Subtitles, summary tickers, and pull quotes have their styled variants
- Advertisement stories have centered text, full border, and slightly darker background

Stop the dev server.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/components/masthead.css app/assets/stylesheets/components/story.css
git commit -m "feat(css): add masthead and story component styles"
```

---

### Task 6: Add the front-page grid container and apply it to the view

The grid is a 4-column CSS Grid with `grid-auto-flow: row dense` (tetris-style packing). Column count and row unit are theme-overridable via custom properties. Default values in `base/tokens.css` make the grid work with whatever theme is active (or with no theme — pages fall back to a 4-column auto-height grid).

**Files:**
- Create: `app/assets/stylesheets/base/grid.css`
- Modify: `app/views/editions/show.html.erb`

- [ ] **Step 1: Create `app/assets/stylesheets/base/grid.css`**

```css
/*
 * Front page grid container.
 *
 * Column count and row unit are theme-overridable via custom properties.
 * grid-auto-flow: row dense packs items into the earliest empty cell they
 * fit, handling variable story counts gracefully.
 */

.front-page-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-flow: row dense;
  grid-auto-rows: var(--grid-row-unit);
  gap: var(--column-gap);
  padding: 0 1rem 2rem;
}
```

- [ ] **Step 2: Wrap the story loop in `.front-page-grid` in `app/views/editions/show.html.erb`**

```erb
<%= render "masthead", edition: @edition %>

<div class="front-page-grid">
  <% @stories.each do |story| %>
    <%= render "story", story: story %>
  <% end %>
</div>
```

- [ ] **Step 3: Verify in the browser**

```bash
bin/dev
```

Open `http://localhost:3000/newspapers/1/editions/1`. Expected:
- Stories now lay out in 4 equal columns
- Each story takes 1 column by default (spans haven't been set per type yet — that's Task 7)
- The grid creates noticeable horizontal gaps between stories
- Layout looks compressed; this is intentional — Task 7 will give each story type the right width

Stop the dev server.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/base/grid.css app/views/editions/show.html.erb
git commit -m "feat(css): add front-page grid container with dense packing"
```

---

### Task 7: Theme the story slot dimensions for Pryce of Progress

The final piece: tell the Pryce theme how big each story type should be. Major spans the full width (4 cols). Secondary takes half (2 cols). Tertiary is a tall single column (1 col × 2 rows). Advertisements are squares (1 col × 1 row, locked by `aspect-ratio`). A fixed `--grid-row-unit` makes the "2 rows tall" and "1×1 square" measurements relate to each other.

**Files:**
- Modify: `app/assets/stylesheets/themes/pryce_of_progress.css`

- [ ] **Step 1: Update `app/assets/stylesheets/themes/pryce_of_progress.css`**

```css
/*
 * Theme: Pryce of Progress
 * Character: Amateur yellow rag. Cheap drama. Aged newsprint.
 *
 * Google Fonts is imported here so each newspaper carries its own type
 * stack. Future newspapers add their own @import in their own theme file.
 */

@import url('https://fonts.googleapis.com/css2?family=Rye&family=Alfa+Slab+One&family=Libre+Baskerville:ital,wght@0,400;0,700;1,400&display=swap');

[data-newspaper="pryce-of-progress"] {
  --color-paper:      #f2e8c9;
  --color-ink:        #2c1810;
  --color-ink-muted:  #5c3d2e;
  --color-rule:       #2c1810;
  --color-accent:     #8b1a1a;

  --font-masthead:    "Rye", serif;
  --font-headline:    "Alfa Slab One", serif;
  --font-body:        "Libre Baskerville", Georgia, serif;

  --grid-row-unit:    220px;
}

[data-newspaper="pryce-of-progress"] .story--major {
  grid-column: span 4;
}

[data-newspaper="pryce-of-progress"] .story--secondary {
  grid-column: span 2;
}

[data-newspaper="pryce-of-progress"] .story--tertiary {
  grid-column: span 1;
  grid-row: span 2;
}

[data-newspaper="pryce-of-progress"] .story--advertisement {
  grid-column: span 1;
  aspect-ratio: 1;
}
```

The selectors are written without CSS nesting for maximum compatibility — Rails 8 / Propshaft serves CSS as-is, and while modern browsers support nesting natively, flat selectors keep the file readable and tool-agnostic.

- [ ] **Step 2: Verify in the browser**

```bash
bin/dev
```

Open `http://localhost:3000/newspapers/1/editions/1`. Expected with seed data (1 major + 1 secondary + 1 tertiary + 5 advertisements):
- **Row 1:** Major story spans the full width (all 4 columns)
- **Row 2:** Secondary story takes 2 columns; tertiary takes 1 column (spanning rows 2-3); an advertisement takes the last column as a square
- **Row 3:** Advertisements fill into the cells not occupied by the tertiary
- **Row 4 onward:** Remaining advertisements continue as squares
- All advertisements are visually square
- Tertiary story is visibly taller than the surrounding ads

Browse the layout and confirm the "tetris" packing — no gaps under the secondary in row 2 because the dense flow puts the first ad there.

Stop the dev server.

- [ ] **Step 3: Run the full test suite**

```bash
bin/rails test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/themes/pryce_of_progress.css
git commit -m "feat(css): theme Pryce story slot dimensions (4/2/1×2/1²)"
```

---

## Definition of Done

After Task 7, opening `http://localhost:3000/newspapers/1/editions/1` shows the Pryce of Progress edition rendered as a real newspaper front page:

- Centered masthead with the newspaper name in Rye, an italic subtitle, an attention bar with rusty-red emphasis, and a triple double border below
- A 4-column CSS Grid below the masthead, packed dense
- The major lead story spanning the full width with Alfa Slab One headline, supertitle, subtitle, summary ticker, byline, justified body with paragraph breaks, and a pull quote
- The secondary story at half width, also with all its fields
- The tertiary story narrow but tall
- Multiple square advertisements filling the remaining grid cells, centered and lightly tinted

All Minitest tests pass (8 controller + 11 model + 5 newspaper + 6 edition = roughly 30 tests, depending on prior state).

Phase 3c (overflow + clipping overlay) will add the "Continued on page X" affordance and the Turbo Frame clipping for stories whose body exceeds their slot.
