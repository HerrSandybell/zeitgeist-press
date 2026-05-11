# "Continued on page #" Overflow Overlay — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a story's body overflows its grid cell on the edition front page, show a "Continued on page #" link; clicking it opens a dimmed newspaper-cutout overlay containing the full story, loaded via Turbo Frame.

**Architecture:** A Stimulus `overflow` controller on each `<article>` measures `scrollHeight > clientHeight` after web fonts load and reveals an otherwise-hidden link. The link is a Turbo Frame link targeting a single page-level `<turbo-frame id="story-overlay">`. A second Stimulus `overlay-frame` controller dims the backdrop on `turbo:frame-load` and dismisses on ESC / click-outside. The server's `StoriesController#show_full` renders the full `StoryComponent` inside a rotated paper-cutout wrapper with `layout: false`.

**Tech Stack:** Rails 8.1, ViewComponent, Hotwire Turbo (Frames), Stimulus, Propshaft, Minitest, Capybara + Selenium for system tests.

**Spec:** [docs/superpowers/specs/2026-05-11-continued-on-page-overlay-design.md](../specs/2026-05-11-continued-on-page-overlay-design.md)

---

## File Map

### New files
| Path | Purpose |
|---|---|
| `app/controllers/stories_controller.rb` | One action: `#show_full` |
| `app/views/stories/show_full.html.erb` | Turbo Frame response with cutout wrapper |
| `app/javascript/controllers/overflow_controller.js` | Per-story overflow detection |
| `app/javascript/controllers/overlay_frame_controller.js` | Backdrop + ESC/click-outside dismiss |
| `app/assets/stylesheets/components/story_overlay.css` | Backdrop, cutout, rotation |
| `test/controllers/stories_controller_test.rb` | `#show_full` tests |
| `test/application_system_test_case.rb` | Capybara base class |
| `test/system/story_overflow_test.rb` | End-to-end overflow → overlay flow |

### Modified files
| Path | Change |
|---|---|
| `app/models/story.rb` | Add `continued_page` method (`position + 1`) |
| `app/components/story_component.html.erb` | Add `data-controller="overflow"`, `data-story-id`, hidden continued link |
| `app/views/editions/show.html.erb` | Add overlay container with `<turbo-frame id="story-overlay">` |
| `config/routes.rb` | Add `resources :stories, only: [] do; member do; get :full, action: :show_full; end; end` |
| `app/assets/stylesheets/base/grid.css` | Change `grid-auto-rows` to fixed `var(--grid-row-unit)` |
| `app/assets/stylesheets/components/story.css` | Add overflow clipping + fade gradient + link positioning |
| `test/components/story_component_test.rb` | Tests for data attributes + continued link |
| `test/fixtures/stories.yml` | Add one long-overflow and verify one short-fit fixture |

`application.css` does NOT need a new import: `stylesheet_link_tag :app` in the application layout auto-picks up every CSS file under `app/assets/stylesheets/`.

---

## Task 1: Add `continued_page` to the `Story` model

**Files:**
- Modify: `app/models/story.rb`
- Test: `test/models/story_test.rb` (may need to be created if absent)

- [ ] **Step 1: Check whether `test/models/story_test.rb` exists**

Run: `ls test/models/story_test.rb`

If missing, create it with this scaffold:

```ruby
require "test_helper"

class StoryTest < ActiveSupport::TestCase
end
```

- [ ] **Step 2: Write the failing test**

Add inside the `StoryTest` class in `test/models/story_test.rb`:

```ruby
test "continued_page returns position + 1" do
  story = stories(:one)
  story.position = 0
  assert_equal 1, story.continued_page

  story.position = 7
  assert_equal 8, story.continued_page
end

test "continued_page treats nil position as 0" do
  story = stories(:one)
  story.position = nil
  assert_equal 1, story.continued_page
end
```

The nil case matters: the `position` column is nullable in the schema, and several existing fixtures (e.g., `stories(:one)`) don't set it. Without this guard, `continued_page` crashes when called on those stories.

- [ ] **Step 3: Run the test and verify it fails**

Run: `bin/rails test test/models/story_test.rb`
Expected: `NoMethodError: undefined method 'continued_page'` (or similar).

- [ ] **Step 4: Implement the method**

In `app/models/story.rb`, inside the `Story` class, after the `validates` line:

```ruby
def continued_page
  (position || 0) + 1
end
```

The full file should now read:

```ruby
class Story < ApplicationRecord
  belongs_to :edition, optional: true

  enum :story_type, { major: 0, secondary: 1, tertiary: 2, advertisement: 3 }

  validates :story_type, :headline, :body, presence: true

  def continued_page
    (position || 0) + 1
  end
end
```

- [ ] **Step 5: Run the test and verify it passes**

Run: `bin/rails test test/models/story_test.rb`
Expected: 2 runs, 3 assertions, 0 failures, 0 errors.

- [ ] **Step 6: Commit**

```bash
git add app/models/story.rb test/models/story_test.rb
git commit -m "$(cat <<'EOF'
feat(model): add Story#continued_page derived from position

Used by the "Continued on page #" link and the overlay masthead.
Page numbers are decorative — derived rather than authored.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add stories route and `StoriesController#show_full` skeleton

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/stories_controller.rb`
- Create: `test/controllers/stories_controller_test.rb`

- [ ] **Step 1: Write the failing controller test**

Create `test/controllers/stories_controller_test.rb`:

```ruby
require "test_helper"

class StoriesControllerTest < ActionDispatch::IntegrationTest
  test "show_full returns 200 for an existing story" do
    get full_story_url(stories(:one))
    assert_response :success
  end

  test "show_full returns 404 for a missing story" do
    get full_story_url(id: 999_999)
    assert_response :not_found
  end
end
```

- [ ] **Step 2: Run the test and verify it fails**

Run: `bin/rails test test/controllers/stories_controller_test.rb`
Expected: `NameError: undefined local variable or method 'full_story_url'` (the route helper doesn't exist yet).

- [ ] **Step 3: Add the route**

In `config/routes.rb`, add this block above `root "newspapers#index"`:

```ruby
resources :stories, only: [] do
  member do
    get :full, action: :show_full
  end
end
```

The full file should be:

```ruby
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :newspapers, only: [] do
    resources :editions, only: [:show]
  end

  resources :stories, only: [] do
    member do
      get :full, action: :show_full
    end
  end

  root "newspapers#index"
end
```

- [ ] **Step 4: Create the controller**

Create `app/controllers/stories_controller.rb`:

```ruby
class StoriesController < ApplicationController
  def show_full
    @story = Story.find(params[:id])
    render :show_full, layout: false
  end
end
```

- [ ] **Step 5: Create a stub view**

Create `app/views/stories/show_full.html.erb` with placeholder content (will be filled in Task 3):

```erb
<turbo-frame id="story-overlay">
  <%# Filled in next task %>
</turbo-frame>
```

- [ ] **Step 6: Run the test and verify it passes**

Run: `bin/rails test test/controllers/stories_controller_test.rb`

Expected: 2 runs, 2 assertions, 0 failures.

The 404 test relies on `ActiveRecord::RecordNotFound` being rescued as 404 in test env — Rails' default behavior.

- [ ] **Step 7: Commit**

```bash
git add config/routes.rb app/controllers/stories_controller.rb \
        app/views/stories/show_full.html.erb \
        test/controllers/stories_controller_test.rb
git commit -m "$(cat <<'EOF'
feat(stories): add StoriesController#show_full route and skeleton

Member route GET /stories/:id/full. Bare layout for Turbo Frame use.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Fill in the `show_full` view (newspaper cutout)

**Files:**
- Modify: `app/views/stories/show_full.html.erb`
- Modify: `test/controllers/stories_controller_test.rb`

- [ ] **Step 1: Extend the controller test**

In `test/controllers/stories_controller_test.rb`, add inside the class (after the existing tests):

```ruby
test "show_full renders the cutout wrapper containing the full story" do
  story = stories(:one)
  get full_story_url(story)

  assert_select "turbo-frame#story-overlay" do
    assert_select "article.story-cutout.story-cutout--major"
    assert_select ".story-cutout__masthead", text: /Page 1/
    assert_select ".story-cutout__footer"
    assert_select ".story", text: /#{story.headline}/
  end
end

test "show_full does not render the application layout" do
  get full_story_url(stories(:one))
  assert_no_match(/<body/, response.body)
end

test "show_full carries the newspaper slug for theme scoping" do
  get full_story_url(stories(:one))

  assert_select "article.story-cutout[data-newspaper='the-daily-chronicle']"
end
```

Note: `stories(:one)` is `position: 0` in the fixture (default), so `continued_page` returns `1`. Fixture `editions(:one)` belongs to `newspapers(:one)` which is "The Daily Chronicle" → slug `the-daily-chronicle`.

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bin/rails test test/controllers/stories_controller_test.rb`
Expected: 3 failures — the cutout elements aren't in the view yet.

- [ ] **Step 3: Write the view template**

Replace `app/views/stories/show_full.html.erb` with:

```erb
<turbo-frame id="story-overlay">
  <article class="story-cutout story-cutout--<%= @story.story_type %>"
           data-newspaper="<%= @story.edition&.newspaper&.slug %>">
    <header class="story-cutout__masthead">
      <%= @story.edition&.newspaper&.name %> — Page <%= @story.continued_page %>
    </header>

    <%= render StoryComponent.new(story: @story) %>

    <footer class="story-cutout__footer">— continued from page 1</footer>
  </article>
</turbo-frame>
```

- [ ] **Step 4: Run the tests and verify they pass**

Run: `bin/rails test test/controllers/stories_controller_test.rb`
Expected: 5 runs, all passing.

- [ ] **Step 5: Commit**

```bash
git add app/views/stories/show_full.html.erb test/controllers/stories_controller_test.rb
git commit -m "$(cat <<'EOF'
feat(views): render full-story cutout for Turbo Frame overlay

Wraps StoryComponent in a rotated paper card with masthead and footer.
data-newspaper carries the theme slug so tokens apply inside the overlay.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Add overflow + fit fixtures for system tests

**Files:**
- Modify: `test/fixtures/stories.yml`

System tests need:
- One story with a body long enough to overflow the 14rem grid cell
- One story (existing) with a body short enough to fit

Existing fixture `stories(:one)` has body `"The full text of the front page story."` — fits easily. Existing `stories(:tertiary_one)` body fits too. We just need to add one long story.

- [ ] **Step 1: Add the long-overflow fixture**

Append to `test/fixtures/stories.yml`:

```yaml
long_major:
  edition: one
  story_type: major
  position: 10
  headline: A Lengthy Dispatch on the Affairs of State
  body: |
    The first volley of correspondence arrived in the small hours of Osenday morning, sealed with the crimson wax of the Chancellery and bearing the unmistakable hand of the Sub-Minister himself.

    Officers of the Watch were dispatched to seven separate addresses across the Municipal Quarter, each summons more peculiar than the last. By dawn, three citizens of considerable standing had been taken into protective custody and a fourth had vanished entirely.

    Our correspondent witnessed the dispatch of a runner — a small, soot-faced boy of perhaps eleven years — bearing a sealed packet from the Office of the Lord Mayor toward the Hall of Inquiry. The boy refused all questions, citing the gravity of the cargo and the consequences of indiscretion.

    By midday the Commissioner had convened an emergency session of the Bench, and by evening the broadsheets of three rival publications had each printed a different account of the morning's events. The truth, as is so often the case in this city, remained the property of those few who had no interest in its publication.

    A statement is expected from the Office of the Lord Mayor before the close of business tomorrow. Our correspondent will be in attendance, notebook in hand and instincts on edge.
```

- [ ] **Step 2: Verify existing tests still pass**

Run: `bin/rails test`
Expected: All previously-passing tests still pass; no new failures.

- [ ] **Step 3: Commit**

```bash
git add test/fixtures/stories.yml
git commit -m "$(cat <<'EOF'
test(fixtures): add long_major story fixture for overflow tests

Body is long enough to overflow a 14rem grid cell at Pryce of Progress
3-column layout. Used by the upcoming system tests.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Update `StoryComponent` template with data attributes and continued link

**Files:**
- Modify: `app/components/story_component.html.erb`
- Modify: `test/components/story_component_test.rb`

- [ ] **Step 1: Write the failing tests**

Add to `test/components/story_component_test.rb` inside the class:

```ruby
test "renders overflow controller data attributes" do
  story = stories(:one)
  render_inline(StoryComponent.new(story: story))

  assert_selector "article[data-controller='overflow']"
  assert_selector "article[data-story-id='#{story.id}']"
end

test "renders hidden continued link with derived page number" do
  story = stories(:one)
  story.position = 3
  render_inline(StoryComponent.new(story: story))

  assert_selector "a.story-continued-link[data-overflow-target='link'][hidden]",
                  text: /Continued on page 4/
end

test "continued link targets the story-overlay turbo frame" do
  story = stories(:one)
  render_inline(StoryComponent.new(story: story))

  assert_selector "a.story-continued-link[data-turbo-frame='story-overlay']"
end
```

- [ ] **Step 2: Run the tests and verify they fail**

Run: `bin/rails test test/components/story_component_test.rb`
Expected: 3 new failures (data-controller, data-story-id, continued link not present).

- [ ] **Step 3: Update the template**

Replace `app/components/story_component.html.erb` with:

```erb
<article class="story story--<%= @story.story_type %>"
         data-controller="overflow"
         data-story-id="<%= @story.id %>">
  <% if @story.supertitle.present? %>
    <p class="story-supertitle"><%= @story.supertitle %></p>
  <% end %>

  <h2 class="headline headline--<%= @story.story_type %>"><%= @story.headline %></h2>

  <% if @story.subtitle.present? %>
    <p class="story-subtitle"><%= @story.subtitle %></p>
  <% end %>

  <% if @story.summary_ticker.present? %>
    <p class="story-ticker"><%= @story.summary_ticker %></p>
  <% end %>

  <% if @story.author.present? %>
    <p class="story-byline">By <%= @story.author %></p>
  <% end %>

  <div class="story-body">
    <% if @story.quote.present? %>
      <%= simple_format(body_halves.first) %>
      <blockquote class="story-quote">
        <%= @story.quote %>
        <% if @story.quote_origin.present? %>
          <cite>— <%= @story.quote_origin %></cite>
        <% end %>
      </blockquote>
      <%= simple_format(body_halves.last) if body_halves.last.present? %>
    <% else %>
      <%= simple_format(@story.body) %>
    <% end %>
  </div>

  <a class="story-continued-link"
     data-overflow-target="link"
     data-turbo-frame="story-overlay"
     href="<%= full_story_path(@story) %>"
     hidden>Continued on page <%= @story.continued_page %> »</a>
</article>
```

- [ ] **Step 4: Run all component tests and verify they pass**

Run: `bin/rails test test/components/story_component_test.rb`
Expected: 8 runs, all passing (5 existing + 3 new).

- [ ] **Step 5: Run the full test suite to verify nothing else broke**

Run: `bin/rails test`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add app/components/story_component.html.erb test/components/story_component_test.rb
git commit -m "$(cat <<'EOF'
feat(component): wire StoryComponent for overflow detection

Adds data-controller="overflow", data-story-id, and a hidden
"Continued on page N »" link that targets the story-overlay Turbo Frame.
The Stimulus controller (to follow) unhides the link when the article
clips its content.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Change grid to fixed-height rows

**Files:**
- Modify: `app/assets/stylesheets/base/grid.css`

This is the visual change that creates the overflow condition in the first place.

- [ ] **Step 1: Replace `grid-auto-rows` with fixed height**

Replace `app/assets/stylesheets/base/grid.css` with:

```css
/*
 * Front page grid container.
 *
 * Row height is fixed (theme-overridable via --grid-row-unit) so that
 * stories which exceed their cell clip and show a "Continued" link.
 */

.front-page-grid {
  display: grid;
  grid-template-columns: repeat(var(--grid-columns), 1fr);
  grid-auto-rows: var(--grid-row-unit);
  gap: var(--column-gap);
  padding: 0 1rem 2rem;
}
```

The change: `grid-auto-rows: minmax(var(--grid-row-unit), auto)` → `grid-auto-rows: var(--grid-row-unit)`. The comment is updated to match.

- [ ] **Step 2: Run the full test suite**

Run: `bin/rails test`
Expected: All tests still pass — this CSS change doesn't affect any Ruby-level test.

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/base/grid.css
git commit -m "$(cat <<'EOF'
feat(css): fix grid row height so cells clip overflowing content

Stories that exceed the row height are now clipped at the cell boundary,
which is the precondition for the "Continued on page #" link.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Add story clipping + fade gradient + link positioning CSS

**Files:**
- Modify: `app/assets/stylesheets/components/story.css`

- [ ] **Step 1: Append the new rules**

Append to `app/assets/stylesheets/components/story.css`:

```css
.story {
  position: relative;
  overflow: hidden;
}

.story--overflows .story-body {
  padding-bottom: 2rem;
}

.story--overflows::after {
  content: "";
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 4.5rem;
  background: linear-gradient(to bottom, transparent 0%, var(--color-paper) 55%);
  pointer-events: none;
}

.story-continued-link {
  position: absolute;
  bottom: 0.5rem;
  right: 0.75rem;
  font-family: var(--font-body);
  font-style: italic;
  font-size: 0.85rem;
  color: var(--color-accent);
  text-decoration: none;
  z-index: 1;
}

.story-continued-link:hover {
  text-decoration: underline;
}
```

Note: the existing `.story` rule (with padding and border-top) is preserved — these new declarations *extend* it by adding `position: relative` and `overflow: hidden`. The existing `.story--advertisement` rule already has `overflow: hidden`; the new declaration on the base `.story` is redundant for ads but harmless.

After this step the file should read in full:

```css
/*
 * Story component — wrappers and field-level type for the _story partial.
 * Per-newspaper themes override .story--<type> column/row spans.
 */

.story {
  padding: 1rem;
  border-top: var(--rule-width) solid var(--color-rule);
  position: relative;
  overflow: hidden;
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
  overflow: hidden;
  border: var(--rule-width) solid var(--color-rule);
  background-color: color-mix(in srgb, var(--color-paper) 92%, var(--color-ink) 8%);
}

.story--advertisement .story-body {
  text-align: center;
  font-size: 0.875rem;
}

.story--overflows .story-body {
  padding-bottom: 2rem;
}

.story--overflows::after {
  content: "";
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 4.5rem;
  background: linear-gradient(to bottom, transparent 0%, var(--color-paper) 55%);
  pointer-events: none;
}

.story-continued-link {
  position: absolute;
  bottom: 0.5rem;
  right: 0.75rem;
  font-family: var(--font-body);
  font-style: italic;
  font-size: 0.85rem;
  color: var(--color-accent);
  text-decoration: none;
  z-index: 1;
}

.story-continued-link:hover {
  text-decoration: underline;
}
```

- [ ] **Step 2: Run the full test suite**

Run: `bin/rails test`
Expected: All tests still pass.

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/components/story.css
git commit -m "$(cat <<'EOF'
feat(css): clip overflowing stories and style continued link

- .story now clips overflow and is positioned for the link
- .story--overflows::after renders the fade-to-paper gradient
- .story-continued-link sits bottom-right in the clear area

Gradient height (4.5rem, opaque by 55%) leaves clear paper below for the
link so it never overlaps fading body text.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Create `story_overlay.css` (backdrop + cutout)

**Files:**
- Create: `app/assets/stylesheets/components/story_overlay.css`

- [ ] **Step 1: Write the file**

Create `app/assets/stylesheets/components/story_overlay.css`:

```css
/*
 * Story overlay — dimmed backdrop and rotated paper-cutout card
 * shown when the user clicks "Continued on page #".
 *
 * The .overlay-frame container is permanent in the DOM but only
 * receives pointer events and a dark backdrop when .overlay-frame--open
 * is added by overlay_frame_controller.js (on turbo:frame-load).
 */

.overlay-frame {
  position: fixed;
  inset: 0;
  background: rgba(20, 15, 10, 0);
  pointer-events: none;
  transition: background 200ms ease;
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
}

.overlay-frame--open {
  background: rgba(20, 15, 10, 0.85);
  pointer-events: auto;
}

.overlay-frame__frame {
  display: block;
  max-width: min(90vw, 56rem);
  max-height: 85vh;
  overflow-y: auto;
}

.story-cutout {
  background: var(--color-paper);
  color: var(--color-ink);
  font-family: var(--font-body);
  padding: 1.5rem 2rem;
  border: 1px solid var(--color-rule);
  box-shadow: 3px 4px 24px rgba(0, 0, 0, 0.5),
              0 1px 4px rgba(0, 0, 0, 0.3);
  transform: rotate(-0.8deg);
}

.story-cutout--secondary {
  transform: rotate(1deg);
  max-width: 36rem;
}

.story-cutout--tertiary {
  transform: rotate(-0.5deg);
  max-width: 28rem;
}

.story-cutout--advertisement {
  transform: rotate(1.5deg);
  max-width: 22rem;
}

.story-cutout__masthead {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-accent);
  border-bottom: 1px solid var(--color-rule);
  padding-bottom: 0.5rem;
  margin-bottom: 0.75rem;
}

.story-cutout__footer {
  font-size: 0.75rem;
  font-style: italic;
  color: var(--color-ink-muted);
  text-align: right;
  border-top: 1px solid var(--color-rule);
  padding-top: 0.5rem;
  margin-top: 1rem;
}
```

- [ ] **Step 2: Verify Propshaft picks up the new file**

Run: `bin/rails runner 'ac = ActionController::Base.helpers; puts ac.stylesheet_link_tag(:app)' | grep story_overlay`

Expected: One line of output containing `story_overlay-<hash>.css`. The `:app` helper auto-discovers all CSS files; no `application.css` edit needed.

- [ ] **Step 3: Run the full test suite**

Run: `bin/rails test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/components/story_overlay.css
git commit -m "$(cat <<'EOF'
feat(css): add overlay backdrop and newspaper-cutout styling

Dark backdrop fades in via .overlay-frame--open. Cutout is a slightly
rotated paper card with type-specific widths and rotations. Theme
tokens flow through via the data-newspaper attribute on the cutout.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Create the `overflow` Stimulus controller

**Files:**
- Create: `app/javascript/controllers/overflow_controller.js`

The Stimulus eager loader (`eagerLoadControllersFrom("controllers", application)` in `app/javascript/controllers/index.js`) automatically registers any `_controller.js` file in the directory — no manual import needed.

- [ ] **Step 1: Write the controller**

Create `app/javascript/controllers/overflow_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Detects whether a story article's content exceeds its grid cell.
// If so: reveals the "Continued" link and tags the article with
// .story--overflows (which triggers the fade gradient in CSS).
//
// We measure this.element (the <article>) because the grid pins it to
// var(--grid-row-unit) and clips with overflow: hidden. The story-body
// itself has no fixed height — measuring it would always return 0 overflow.
//
// document.fonts.ready is essential: web fonts load asynchronously, and
// measuring before they arrive produces false negatives based on fallback
// font metrics.
export default class extends Controller {
  static targets = ["link"]

  connect() {
    document.fonts.ready.then(() => this.detectOverflow())
  }

  detectOverflow() {
    if (this.element.scrollHeight > this.element.clientHeight) {
      if (this.hasLinkTarget) {
        this.linkTarget.hidden = false
      }
      this.element.classList.add("story--overflows")
    }
  }
}
```

The `hasLinkTarget` guard is defensive — Stimulus exposes it for free, and it protects against templates that for any reason render the article without the link (e.g., a future variant).

- [ ] **Step 2: Run the full test suite**

Run: `bin/rails test`
Expected: All tests still pass. (Stimulus controllers don't break Ruby tests.)

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/overflow_controller.js
git commit -m "$(cat <<'EOF'
feat(js): add overflow Stimulus controller for per-story detection

Measures the article element (the one constrained by grid-auto-rows)
after fonts load. Reveals the link target and adds .story--overflows
when content exceeds the cell height.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Create the `overlay-frame` Stimulus controller

**Files:**
- Create: `app/javascript/controllers/overlay_frame_controller.js`

- [ ] **Step 1: Write the controller**

Create `app/javascript/controllers/overlay_frame_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Owns the dimmed backdrop and the Turbo Frame that holds the cutout.
// Lifecycle:
//   - turbo:frame-load@window  -> #show (backdrop fades in, ESC listener attached)
//   - click on .overlay-frame  -> #close (the backdrop itself)
//   - click on the frame       -> #stopPropagation (clicking the cutout doesn't dismiss)
//   - keydown ESC anywhere     -> #close (registered globally while open)
//
// On close, we clear the frame's innerHTML so Turbo refetches the next
// time the same story is reopened. Without this, Turbo's frame cache
// would skip the request and the frame-load event would never fire.
export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.closeOnEscape = this.closeOnEscape.bind(this)
  }

  show() {
    this.element.classList.add("overlay-frame--open")
    document.addEventListener("keydown", this.closeOnEscape)
  }

  close() {
    this.element.classList.remove("overlay-frame--open")
    if (this.hasFrameTarget) {
      this.frameTarget.innerHTML = ""
    }
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
```

- [ ] **Step 2: Run the full test suite**

Run: `bin/rails test`
Expected: All tests still pass.

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/overlay_frame_controller.js
git commit -m "$(cat <<'EOF'
feat(js): add overlay-frame Stimulus controller for backdrop + dismiss

Listens for turbo:frame-load to dim the backdrop; dismisses on
click-outside or ESC. Clears the frame innerHTML on close so reopens
trigger a fresh server fetch (Turbo Frame caches by default).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Add the overlay container to the edition view

**Files:**
- Modify: `app/views/editions/show.html.erb`

- [ ] **Step 1: Add the overlay block**

Replace `app/views/editions/show.html.erb` with:

```erb
<div class="newspaper-page">
  <%= render "masthead", edition: @edition %>

  <div class="front-page-grid">
    <% @stories.each do |story| %>
      <%= render StoryComponent.new(story: story) %>
    <% end %>
  </div>
</div>

<div class="overlay-frame"
     data-controller="overlay-frame"
     data-action="turbo:frame-load@window->overlay-frame#show click->overlay-frame#close">
  <turbo-frame id="story-overlay"
               class="overlay-frame__frame"
               data-overlay-frame-target="frame"
               data-action="click->overlay-frame#stopPropagation"></turbo-frame>
</div>
```

The overlay sits *outside* `.newspaper-page` so its `position: fixed` covers the entire viewport.

- [ ] **Step 2: Run the existing editions controller test**

Run: `bin/rails test test/controllers/editions_controller_test.rb`
Expected: All 4 tests still pass.

- [ ] **Step 3: Run the full test suite**

Run: `bin/rails test`
Expected: All tests pass.

- [ ] **Step 4: Commit**

```bash
git add app/views/editions/show.html.erb
git commit -m "$(cat <<'EOF'
feat(views): wire overlay container into edition show page

Empty <turbo-frame id="story-overlay"> wrapped by .overlay-frame
which Stimulus toggles on turbo:frame-load. Sits outside the
newspaper-page so the backdrop covers the full viewport.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Set up Capybara system test infrastructure

**Files:**
- Create: `test/application_system_test_case.rb`
- Create: `test/system/.keep` (placeholder so the directory exists)

The Rails scaffold doesn't include a `test/system/` directory by default in this project. Capybara and selenium-webdriver are already in the Gemfile.

- [ ] **Step 1: Create the base test case**

Create `test/application_system_test_case.rb`:

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
end
```

- [ ] **Step 2: Create the system test directory**

Run: `mkdir -p test/system && touch test/system/.keep`

- [ ] **Step 3: Smoke-test the infrastructure with a placeholder**

Create a temporary smoke test at `test/system/_smoke_test.rb`:

```ruby
require "application_system_test_case"

class SmokeTest < ApplicationSystemTestCase
  test "the rails app boots and responds" do
    visit "/up"
    assert_text(/./)  # any text — just confirming the browser drove the request
  end
end
```

- [ ] **Step 4: Run the smoke test**

Run: `bin/rails test:system test/system/_smoke_test.rb`
Expected: 1 run, 1 assertion, 0 failures. (If Chrome/chromedriver isn't installed, this will fail with a driver error — install with `npx playwright install chromium` or the system's chromedriver package, then re-run.)

- [ ] **Step 5: Delete the smoke test (infrastructure proven)**

Run: `rm test/system/_smoke_test.rb`

- [ ] **Step 6: Commit**

```bash
git add test/application_system_test_case.rb test/system/.keep
git commit -m "$(cat <<'EOF'
test(system): add Capybara system test infrastructure

Headless Chrome via Selenium. Required for Phase 3c overflow tests
that need a real browser to exercise Stimulus + Turbo Frame behavior.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: System test — clicking "Continued" opens the overlay

**Files:**
- Create: `test/system/story_overflow_test.rb`

- [ ] **Step 1: Write the first system test**

Create `test/system/story_overflow_test.rb`:

```ruby
require "application_system_test_case"

class StoryOverflowTest < ApplicationSystemTestCase
  setup do
    @edition   = editions(:one)
    @newspaper = @edition.newspaper
    @long      = stories(:long_major)
  end

  test "clicking the continued link opens the overlay with the full story" do
    visit newspaper_edition_path(@newspaper, @edition)

    within "article[data-story-id='#{@long.id}']" do
      assert_selector "a.story-continued-link", visible: true, wait: 5
      click_link(/Continued on page/)
    end

    assert_selector "div.overlay-frame.overlay-frame--open", wait: 5
    assert_selector "turbo-frame#story-overlay article.story-cutout"
    assert_selector ".story-cutout__masthead", text: /Page/
    assert_text @long.headline
  end
end
```

The `wait: 5` on the link assertion is important: the Stimulus controller waits for `document.fonts.ready` before detecting overflow, which takes a moment in a real browser.

- [ ] **Step 2: Run the test**

Run: `bin/rails test:system test/system/story_overflow_test.rb`

Expected: 1 run, 4 assertions, 0 failures.

If it fails, check (in order):
1. Was the long_major fixture body long enough to overflow? Open `/newspapers/1/editions/1` manually in dev to check.
2. Is the JS controller actually running? Check the browser console.
3. Does `headless_chrome` support `document.fonts.ready`? Modern Chrome does — confirm.

- [ ] **Step 3: Commit**

```bash
git add test/system/story_overflow_test.rb
git commit -m "$(cat <<'EOF'
test(system): cover continued-link → overlay-open flow

Visits an edition page, clicks the long-major story's continued link,
asserts the backdrop is open and the cutout is in the frame.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 14: System test — ESC and backdrop click dismiss the overlay

**Files:**
- Modify: `test/system/story_overflow_test.rb`

- [ ] **Step 1: Add the dismissal tests**

Append to the `StoryOverflowTest` class in `test/system/story_overflow_test.rb`:

```ruby
test "pressing ESC closes the overlay" do
  visit newspaper_edition_path(@newspaper, @edition)

  within "article[data-story-id='#{@long.id}']" do
    assert_selector "a.story-continued-link", visible: true, wait: 5
    click_link(/Continued on page/)
  end

  assert_selector ".overlay-frame--open", wait: 5
  find("body").send_keys(:escape)
  assert_no_selector ".overlay-frame--open"
end

test "clicking the backdrop closes the overlay" do
  visit newspaper_edition_path(@newspaper, @edition)

  within "article[data-story-id='#{@long.id}']" do
    assert_selector "a.story-continued-link", visible: true, wait: 5
    click_link(/Continued on page/)
  end

  assert_selector ".overlay-frame--open", wait: 5
  # Click on the backdrop area (top-left corner), not the centered cutout.
  page.execute_script("document.querySelector('.overlay-frame').click()")
  assert_no_selector ".overlay-frame--open"
end

test "clicking the cutout itself does not close the overlay" do
  visit newspaper_edition_path(@newspaper, @edition)

  within "article[data-story-id='#{@long.id}']" do
    assert_selector "a.story-continued-link", visible: true, wait: 5
    click_link(/Continued on page/)
  end

  assert_selector ".overlay-frame--open", wait: 5
  find("article.story-cutout").click
  assert_selector ".overlay-frame--open"  # still open
end
```

For the backdrop test, `execute_script` is used to click the backdrop element directly rather than at a coordinate — Capybara's `click` on a flex-centered container with a child can be ambiguous about which element receives the event.

- [ ] **Step 2: Run the tests**

Run: `bin/rails test:system test/system/story_overflow_test.rb`
Expected: 4 runs (1 existing + 3 new), all passing.

- [ ] **Step 3: Commit**

```bash
git add test/system/story_overflow_test.rb
git commit -m "$(cat <<'EOF'
test(system): cover overlay dismiss interactions

ESC, backdrop click, and the negative case (clicking the cutout itself
does not dismiss). Confirms event propagation is stopped on the frame.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 15: System test — short stories don't show the continued link

**Files:**
- Modify: `test/system/story_overflow_test.rb`

- [ ] **Step 1: Add the negative-case test**

Append to the `StoryOverflowTest` class:

```ruby
test "short stories do not display the continued link" do
  short = stories(:tertiary_one)
  visit newspaper_edition_path(@newspaper, @edition)

  # Wait until the overflow controller has had a chance to run on all
  # stories on the page — the long_major's link surfaces, signaling
  # detection has completed for everyone.
  assert_selector "article[data-story-id='#{@long.id}'] a.story-continued-link",
                  visible: true, wait: 5

  within "article[data-story-id='#{short.id}']" do
    assert_no_selector "a.story-continued-link", visible: true
  end
end
```

- [ ] **Step 2: Run the test**

Run: `bin/rails test:system test/system/story_overflow_test.rb`
Expected: 5 runs total, all passing.

- [ ] **Step 3: Commit**

```bash
git add test/system/story_overflow_test.rb
git commit -m "$(cat <<'EOF'
test(system): assert short stories suppress the continued link

The Stimulus controller only unhides the link when the article actually
clips. Tertiary fixture has a short body that fits inside the cell.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

---

## Task 16: Manual smoke check in the browser

**Files:** None (verification only).

- [ ] **Step 1: Start the dev server**

Run: `bin/dev` (or `bin/rails server`)

- [ ] **Step 2: Visit an edition**

Navigate to `http://localhost:3000/newspapers/1/editions/1` (or the equivalent seed data URL).

- [ ] **Step 3: Verify on the page**

Check by eye:
- [ ] At least one story shows a "Continued on page N »" link in the bottom-right corner.
- [ ] The link sits in a clear paper area (no fading text behind it).
- [ ] Clicking the link opens a dimmed overlay with a slightly rotated newspaper cutout.
- [ ] The cutout displays the masthead, the full story body, and the footer.
- [ ] The Pryce of Progress theme (cream paper, dark ink, period fonts) carries through to the cutout.
- [ ] Pressing ESC closes the overlay.
- [ ] Clicking outside the cutout (on the dim backdrop) closes the overlay.
- [ ] Clicking the cutout itself does *not* close it.
- [ ] Re-opening the same story works after a previous close.
- [ ] Stories that fit their cell (short bodies) do not show the link.

- [ ] **Step 4: Run the full test suite one final time**

Run: `bin/rails test && bin/rails test:system`
Expected: Everything green.

- [ ] **Step 5: Stop the dev server**

Send `Ctrl-C` to the `bin/dev` process.

No commit for this task — pure verification. If you find issues, file them as follow-up tasks rather than amending earlier commits.

---

## Out of Scope (deferred, do not implement)

These were called out in the spec and remain out of scope for Phase 3c:

- `ResizeObserver` re-detection on window resize.
- Cutout entrance animation (only backdrop has a 200ms fade).
- Mobile layout adjustments — desktop-first.
- Removing Alpine.js from the importmap — feature works without it; cleanup is a separate decision.

## When all tasks complete

Use the `superpowers:finishing-a-development-branch` skill to verify tests pass and decide whether to merge locally, open a PR, keep the branch, or discard.
