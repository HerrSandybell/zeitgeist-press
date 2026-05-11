# Phase 3c — "Continued on page #" Overflow Overlay

**Date:** 2026-05-11
**Phase:** 3c (third and final of the design-system arc)
**Status:** Design approved, ready for implementation plan

## Goal

When a story's body content overflows its grid cell on the edition front page, show a "Continued on page #" link in the cell. Clicking the link opens a dimmed overlay containing a newspaper-cutout-styled rendering of the full story, loaded on demand via Turbo Frame.

## Architecture

A Stimulus controller (`overflow`) detects per-story overflow on connect and reveals a "Continued" link only when the story body's `scrollHeight` exceeds its `clientHeight`. The link is a standard Turbo Frame link pointing at `GET /stories/:id/full` and targeting a single page-level `<turbo-frame id="story-overlay">`. A second Stimulus controller (`overlay-frame`) manages the backdrop — it listens for `turbo:frame-load` to dim the page and reveal the cutout, and handles dismissal via click-outside or ESC. The server-side `StoriesController#show_full` action renders the full `StoryComponent` inside a paper-cutout wrapper, with `layout: false` so only the frame markup ships.

The grid changes from `grid-auto-rows: minmax(var(--grid-row-unit), auto)` to fixed `var(--grid-row-unit)` so cells clip content rather than expanding to fit.

## Design Decisions

These were resolved during brainstorming and inform the rest of the spec.

| Decision | Choice | Rationale |
|---|---|---|
| Overflow detection mechanism | CSS clipping + Stimulus JS (`scrollHeight > clientHeight`) | The newspaper page layout is the constraint, not an arbitrary word count. Detection is visual-truth. |
| Truncation indicator | Fade-out gradient + corner link in clear area | Soft, period-appropriate. Gradient is tall enough (4.5rem, opaque by 55%) that the link sits on solid paper, not over fading text. |
| Overlay style | Newspaper cutout on dark backdrop, slightly rotated | On-theme for the gaslight aesthetic; matches the concept doc's "newspaper cutout" description. |
| Overlay column treatment | Story-type-aware: major = 3 columns, secondary = 2, tertiary/ad = 1 | The cutout renders the existing `StoryComponent`, so its existing per-type column styling carries through. |
| Content delivery | Turbo Frame (`GET /stories/:id/full`) | Idiomatic Rails/Hotwire; keeps initial page load free of hidden overlay HTML for every story. |
| Page number in link | Auto-derived from `story.position + 1` | Decorative — the other pages don't exist. Authenticity of the number was deemed unnecessary. |
| JS framework | Stimulus only | Rails/Hotwire-idiomatic; one tool, single mental model; clean fit with ViewComponent. Alpine is unnecessary for this feature. |

## File Structure

### New files

| Path | Responsibility |
|---|---|
| `app/javascript/controllers/overflow_controller.js` | Per-story: detect overflow on connect; reveal "Continued" link if clipped. |
| `app/javascript/controllers/overlay_frame_controller.js` | Page-level: dim backdrop on `turbo:frame-load`; dismiss on click-outside / ESC. |
| `app/controllers/stories_controller.rb` | New minimal controller with one action: `#show_full`. |
| `app/views/stories/show_full.html.erb` | Turbo Frame response rendering the full story inside the cutout wrapper. |
| `app/assets/stylesheets/components/story_overlay.css` | Backdrop, cutout card, rotation, masthead/footer styling. |
| `test/controllers/stories_controller_test.rb` | Tests for `#show_full`. |
| `test/system/story_overflow_test.rb` | End-to-end: overflow detection, link click, ESC dismiss, backdrop dismiss. |

### Modified files

| Path | Change |
|---|---|
| `app/models/story.rb` | Add `continued_page` method returning `position + 1`. Used by both the component template and the cutout view. |
| `app/components/story_component.html.erb` | Add `data-controller="overflow"`, `data-story-id` on the article; conditional "Continued" link with `data-overflow-target="link"`, `data-turbo-frame="story-overlay"`, and `hidden` attribute. |
| `app/views/editions/show.html.erb` | Add page-level overlay container: `<div data-controller="overlay-frame">` wrapping `<turbo-frame id="story-overlay">`. |
| `config/routes.rb` | Add `resources :stories, only: [] do; member do; get :full, action: :show_full; end; end`. |
| `app/assets/stylesheets/base/grid.css` | Change `grid-auto-rows` from `minmax(var(--grid-row-unit), auto)` to `var(--grid-row-unit)`. |
| `app/assets/stylesheets/components/story.css` | Add `overflow: hidden`, `position: relative`, fade gradient via `::after` on `.story--overflows`, link positioning. |
| `app/assets/stylesheets/application.css` | Import new `story_overlay.css`. |
| `test/components/story_component_test.rb` | Add tests: overflow data attributes, continued link page number, frame target. |
| `test/fixtures/stories.yml` | Ensure one story fixture clearly overflows (`long_major`) and one clearly fits (`short_tertiary`) for deterministic system tests. |

## Component Detail

### `StoryComponent` template additions

```erb
<article class="story story--<%= @story.story_type %>"
         data-controller="overflow"
         data-story-id="<%= @story.id %>">
  <!-- existing supertitle, headline, subtitle, ticker, byline -->

  <div class="story-body">
    <!-- existing body rendering with quote-in-middle logic -->
  </div>

  <a class="story-continued-link"
     data-overflow-target="link"
     data-turbo-frame="story-overlay"
     href="<%= full_story_path(@story) %>"
     hidden>Continued on page <%= @story.continued_page %> »</a>
</article>
```

The link starts with `hidden`. The Stimulus controller removes the attribute only if overflow is detected.

### `Story` model addition

```ruby
def continued_page
  position + 1
end
```

Called from both `StoryComponent` (for the "Continued" link) and the cutout's masthead view.

### `overflow_controller.js`

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  connect() {
    document.fonts.ready.then(() => this.detectOverflow())
  }

  detectOverflow() {
    if (this.element.scrollHeight > this.element.clientHeight) {
      this.linkTarget.hidden = false
      this.element.classList.add("story--overflows")
    }
  }
}
```

We measure `this.element` (the `<article>`) because it's the element with the fixed grid-row height and `overflow: hidden`. Measuring `.story-body` would always return zero overflow — that element has no fixed height of its own.

The `document.fonts.ready` wait is essential: web fonts (Libre Baskerville, Alfa Slab One, etc.) load asynchronously. Measuring before they arrive produces false negatives based on fallback-font metrics.

### `overlay_frame_controller.js`

```js
import { Controller } from "@hotwired/stimulus"

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
    this.frameTarget.innerHTML = ""
    document.removeEventListener("keydown", this.closeOnEscape)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }
}
```

### Edition `show.html.erb` overlay block

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

### `StoriesController#show_full`

```ruby
class StoriesController < ApplicationController
  def show_full
    @story = Story.find(params[:id])
    render :show_full, layout: false
  end
end
```

### `app/views/stories/show_full.html.erb`

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

The `data-newspaper` attribute on the cutout re-applies the theme tokens (fonts, paper/ink colours, accents) inside the overlay, since the cutout renders outside the `<body>` element where the slug is currently stamped.

## CSS Detail

### `base/grid.css` — fixed row heights

```css
.front-page-grid {
  display: grid;
  grid-template-columns: repeat(var(--grid-columns), 1fr);
  grid-auto-rows: var(--grid-row-unit);
  gap: var(--column-gap);
  padding: 0 1rem 2rem;
}
```

### `components/story.css` — clipping + fade gradient

```css
.story {
  overflow: hidden;
  position: relative;
}

.story--overflows .story-body {
  padding-bottom: 2rem;
}

.story--overflows::after {
  content: "";
  position: absolute;
  bottom: 0; left: 0; right: 0;
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
}

.story-continued-link:hover { text-decoration: underline; }
```

The gradient only renders when `.story--overflows` is present (added by the Stimulus controller). Stories that fit get no gradient.

### `components/story_overlay.css` — backdrop + cutout

```css
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

.story-cutout--secondary    { transform: rotate(1deg);    max-width: 36rem; }
.story-cutout--tertiary     { transform: rotate(-0.5deg); max-width: 28rem; }
.story-cutout--advertisement{ transform: rotate(1.5deg);  max-width: 22rem; }

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

## Data Flow

```
1. Page load
   ├─ EditionsController#show renders the edition
   ├─ Each StoryComponent emits article with data-controller="overflow"
   │  containing body target and hidden "Continued" link
   └─ Page-level overlay-frame container with empty <turbo-frame id="story-overlay">

2. Stimulus connect
   ├─ Each overflow controller waits for document.fonts.ready
   └─ Compares body.scrollHeight to body.clientHeight
       ├─ overflow → linkTarget.hidden = false + add .story--overflows class
       └─ fits     → link stays hidden, no fade gradient

3. User clicks "Continued on page N »"
   ├─ Link's data-turbo-frame="story-overlay" intercepts the click
   └─ Turbo GETs /stories/:id/full → swaps response into the frame

4. turbo:frame-load fires
   ├─ overlay-frame controller's #show runs
   ├─ Adds .overlay-frame--open class → CSS dims backdrop, reveals cutout
   └─ Registers ESC keyboard listener

5. User dismisses (click outside cutout OR press ESC)
   ├─ overlay-frame#close runs
   ├─ Removes .overlay-frame--open
   ├─ Clears frame innerHTML (forces fresh fetch on next open)
   └─ Unregisters ESC listener

6. Reopen → step 3 repeats with a fresh GET
```

### Edge cases handled

- Stories that don't overflow never show the link — no broken click path.
- Clicking the cutout itself doesn't dismiss the overlay (event propagation stopped on the frame element).
- Re-rendering the StoryComponent dynamically (future Turbo Stream / live edit) re-runs `connect()` automatically; overflow re-detected on the new content.
- Frame innerHTML cleared on close: ensures Turbo refetches on next click of the same story (Turbo Frames cache their last content by default).

### Out of scope (future work)

- **`ResizeObserver` re-detection.** If the user resizes the window while the page is loaded, overflow state doesn't update. For a static front-page archive this is acceptable; a `ResizeObserver` can be added later if needed.
- **Animation polish.** Backdrop fade is in scope (200ms transition); cutout entrance animation is not — it appears with the frame load.
- **Mobile layout adjustments.** The current grid is desktop-first; small-screen behaviour for the overlay is not addressed here.

## Testing Strategy

Minitest + Capybara only, per project constraints.

### Component test (`test/components/story_component_test.rb`)

Additions to existing tests:

```ruby
test "renders overflow detection data attributes" do
  story = stories(:major_one)
  render_inline(StoryComponent.new(story: story))

  assert_selector "article[data-controller='overflow']"
  assert_selector "a[data-overflow-target='link'][hidden]"
end

test "continued link uses derived page number" do
  story = stories(:major_one)  # position = 1
  render_inline(StoryComponent.new(story: story))

  assert_selector "a[data-overflow-target='link']", text: /Continued on page 2/
end

test "continued link targets the story-overlay frame" do
  story = stories(:major_one)
  render_inline(StoryComponent.new(story: story))

  assert_selector "a[data-turbo-frame='story-overlay']"
end
```

Stimulus-driven overflow detection is not tested at the component level — ViewComponent tests render HTML without a real browser, so `scrollHeight` is always 0. That coverage belongs in the system test.

### Controller test (`test/controllers/stories_controller_test.rb`)

```ruby
test "show_full renders the full story in a turbo frame" do
  get full_story_path(stories(:major_one))

  assert_response :success
  assert_select "turbo-frame#story-overlay"
  assert_select ".story-cutout"
end

test "show_full does not render the application layout" do
  get full_story_path(stories(:major_one))

  assert_no_select "body"
end

test "show_full returns 404 for missing story" do
  get full_story_path(id: 999_999)
  assert_response :not_found
end
```

### System test (`test/system/story_overflow_test.rb`)

```ruby
require "application_system_test_case"

class StoryOverflowTest < ApplicationSystemTestCase
  test "clicking continued link opens overlay with full story" do
    visit edition_path(editions(:pryce_issue_one))

    within "[data-story-id='#{stories(:long_major).id}']" do
      click_link(/Continued on page/)
    end

    assert_selector "turbo-frame#story-overlay .story-cutout"
    assert_selector ".overlay-frame--open"
    assert_text stories(:long_major).body.split.last(5).join(" ")
  end

  test "pressing escape closes the overlay" do
    visit edition_path(editions(:pryce_issue_one))
    click_link(/Continued on page/, match: :first)

    assert_selector ".overlay-frame--open"
    find("body").send_keys(:escape)
    assert_no_selector ".overlay-frame--open"
  end

  test "clicking backdrop closes the overlay" do
    visit edition_path(editions(:pryce_issue_one))
    click_link(/Continued on page/, match: :first)

    find(".overlay-frame", visible: true).click
    assert_no_selector ".overlay-frame--open"
  end

  test "short stories do not show continued link" do
    visit edition_path(editions(:pryce_issue_one))

    within "[data-story-id='#{stories(:short_tertiary).id}']" do
      assert_no_link(/Continued on page/)
    end
  end
end
```

### Fixture requirements

To make system tests deterministic, `test/fixtures/stories.yml` needs:
- One story (`long_major` or renamed equivalent) with a body long enough to overflow `--grid-row-unit` (14rem) at its rendered column span.
- One story (`short_tertiary`) with a body short enough to fit cleanly in a single tertiary cell.

Existing fixtures may already satisfy this; the implementation plan will verify and adjust if needed.

## Non-Goals

- **Resize-driven re-detection** — see "out of scope" above.
- **Removing Alpine.js from the project** — this design uses Stimulus only, but does not remove Alpine. Alpine remains pinned in the importmap for any future small interactions. A follow-up decision can retire it once we're sure nothing else needs it.
- **Server-side overflow determination** — explicitly rejected during brainstorming. Overflow is a visual property; the visual layer detects it.
- **Page numbers as an authored field** — explicitly rejected. The number is decorative and derived from story position.
