# Design: Design System Foundation + Edition Front Page

**Date:** 2026-05-10
**Scope:** CSS design system (semantic tokens, per-newspaper theming, typography) and the edition show page (front page layout, story slots, overflow overlay).

## Goal

Establish a design system that supports multiple newspapers with distinct visual identities, and render the edition front page as a styled newspaper with typed story slots and an overflow clipping overlay. This is the M1 reading experience.

## Design System Architecture

### File Structure

```
app/assets/stylesheets/
  base/
    tokens.css          ← semantic custom property declarations + default values
    typography.css      ← Google Fonts imports, base type rules
  themes/
    pryce_of_progress.css  ← newspaper-specific token overrides
  components/
    masthead.css
    story.css
    story_clipping.css  ← overflow overlay
  application.css       ← Propshaft manifest
```

### Theming Mechanism

Each newspaper theme is scoped to a `data-newspaper` attribute on `<body>`. Propshaft serves all stylesheets on every request — no conditional loading. Only the selector matching the current newspaper activates.

`Newspaper` gets a `slug` method:

```ruby
def slug
  name.parameterize
end
```

The application layout stamps it:

```erb
<body data-newspaper="<%= @edition&.newspaper&.slug %>">
```

Pages without an edition (e.g. newspapers index) get no `data-newspaper` value — base token defaults apply.

Adding a new newspaper = one new file in `themes/`.

## Design Tokens

### Token Contract — `base/tokens.css`

All semantic custom properties declared here with neutral defaults. Every theme overrides these.

```css
:root {
  --color-paper:      #ffffff;
  --color-ink:        #000000;
  --color-ink-muted:  #555555;
  --color-rule:       #000000;
  --color-accent:     #000000;

  --font-masthead:    serif;
  --font-headline:    serif;
  --font-body:        serif;

  --rule-width:       1px;
  --column-gap:       1.5rem;
  --grid-row-unit:    auto;  /* set to fixed length in themes to size tertiary/ad cells */
}
```

### Pryce of Progress Theme — `themes/pryce_of_progress.css`

**Character:** Amateur yellow rag. Cheap drama. Aged newsprint.

```css
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
}
```

### Reserved Typography Stacks

Two stacks kept for future newspapers:

**The Broadsheet**
- Masthead: `UnifrakturMaguntia`
- Headlines: `Playfair Display`
- Body: `Lora`

**The Penny Press**
- Masthead: `UnifrakturMaguntia`
- Headlines: `Cormorant Garamond`
- Body: `EB Garamond`

## Typography

Defined in `base/typography.css`. Maps semantic tokens to roles:

| Role | Class | Font token | Notes |
|---|---|---|---|
| Masthead nameplate | `.masthead-title` | `--font-masthead` | Large, centered |
| Attention bar | `.attention-bar` | `--font-headline` | Accent color, bold |
| Major headline | `.headline--major` | `--font-headline` | Largest |
| Secondary headline | `.headline--secondary` | `--font-headline` | Medium |
| Tertiary headline | `.headline--tertiary` | `--font-headline` | Smaller |
| Supertitle | `.story-supertitle` | `--font-body` | Uppercase, letter-spaced |
| Body copy | `.story-body` | `--font-body` | Justified, ~16px, line-height 1.6 |
| Byline | `.story-byline` | `--font-body` | Italic, muted |

Body text is justified — period newspapers always were.

## Edition Front Page Layout

### Layout as Part of the Theme

Layout geometry (grid column count, row unit height, story spans) is per-newspaper, defined in the theme file alongside colors and typography. The base CSS defines the grid container structure and default span values. Each newspaper's theme file overrides them.

This means a future newspaper can use a completely different column count or story proportions without touching shared code.

### Grid

The base grid container — column count and row unit are overridden per theme:

```css
.front-page-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-auto-flow: row dense;
  grid-auto-rows: var(--grid-row-unit, auto);
  gap: var(--column-gap);
}
```

`grid-auto-flow: row dense` enables "tetris-like" packing — the grid looks for the earliest empty cell that fits each item and places it there. This handles variable story counts gracefully: leftover cells under a wide story get filled by smaller stories that come later in the source order. The trade-off is that visual order may differ from DOM order. For an amateur publication like Pryce of Progress, this is acceptable and thematic.

`--grid-row-unit` is a theme-level token. Setting it to a fixed value (e.g. `200px`) gives tertiary and advertisement consistent, relatable heights. Without it, row heights are content-driven.

### Story Slot Dimensions — Pryce of Progress

Defined in `themes/pryce_of_progress.css`. Each story type has a distinct visual footprint:

| Type | Columns | Rows | Effect |
|---|---|---|---|
| major | span 4 | span 1 | Full-width dominant banner |
| secondary | span 2 | span 1 | Half-width, clearly subordinate |
| tertiary | span 1 | span 2 | Narrow column, tall — runs deep |
| advertisement | span 1 | span 1 | Square block via `aspect-ratio: 1` |

```css
[data-newspaper="pryce-of-progress"] {
  --grid-row-unit: 200px;

  .story--major         { grid-column: span 4; }
  .story--secondary     { grid-column: span 2; }
  .story--tertiary      { grid-column: span 1; grid-row: span 2; }
  .story--advertisement { grid-column: span 1; aspect-ratio: 1; }
}
```

Story counts are not fixed. Each edition has at least one major story and a variable mix of the rest. Dense packing handles whatever shows up — wide stories take the top, narrower stories fill the remaining cells in any order that fits.

### Story Ordering

Controller orders by type. Within the same type, stories render in insertion order (database ID). There is no `position` field used.

```ruby
@stories = @edition.stories.order(:story_type)
```

`story_type` enum values (`major: 0, secondary: 1, tertiary: 2, advertisement: 3`) are already in visual hierarchy order.

### Rails Views

```
app/views/editions/
  show.html.erb          ← front page shell (masthead + grid)
  _masthead.html.erb     ← newspaper name, edition label, attention bar
  _story.html.erb        ← shared story partial (locals: story)
  _story_clipping.html.erb ← full story for overlay
```

The `_story` partial renders all story types. The story's `story_type` determines which headline class and `max-height` apply via the `.story--<type>` CSS class stamped on the wrapper.

### Story Scopes

```ruby
# app/models/story.rb
scope :major,          -> { where(story_type: :major) }
scope :secondary,      -> { where(story_type: :secondary) }
scope :tertiary,       -> { where(story_type: :tertiary) }
scope :advertisement,  -> { where(story_type: :advertisement) }
```

## Overflow Overlay

### Detection

A Stimulus controller (`story_controller.js`) on each story slot checks `scrollHeight > clientHeight` after render. If overflowing, it reveals a "Continued on page X" link at the bottom. The page number is a static cosmetic value — there are no actual inside pages in the data model. Each story type maps to a fixed display number (major → 2, secondary → 3, tertiary → 4). This can be a data attribute on the slot element set by the Rails partial.

Story slot height is controlled by the grid (`--grid-row-unit` and `grid-row: span N`), not by `max-height`. All slots use `overflow: hidden` — the grid cell itself acts as the clipping boundary.

### Turbo Frame Overlay

A `<turbo-frame id="story-overlay">` lives in the application layout, outside the grid. The "Continued" link targets this frame. Clicking fetches the story clipping partial.

Alpine.js manages open/close state. When the frame loads, Alpine activates the backdrop. Clicking outside the clipping resets the frame src and closes the overlay.

```html
<div x-data="{ open: false }" @turbo:frame-load.window="open = true">
  <div class="overlay-backdrop"
       x-show="open"
       @click.self="open = false; $refs.frame.src = ''">
    <turbo-frame id="story-overlay" x-ref="frame"></turbo-frame>
  </div>
</div>
```

### Story Clipping Partial

`_story_clipping.html.erb` renders the full story body styled as a paper cutout — aged paper background, prominent drop shadow, slight rotation. Rendered inside the Turbo Frame. Torn-edge effects (CSS `clip-path` or SVG masks) are deferred — V1 uses simple shadow and rotation.

### New Route

```ruby
resources :newspapers, only: [] do
  resources :editions, only: [:show] do
    resources :stories, only: [:show]
  end
end
```

A `StoriesController#show` action fetches the story and renders a view that wraps the clipping partial in `<turbo-frame id="story-overlay">`. Turbo extracts only the matching frame from the response, so no special layout is needed — the standard application layout is fine.

## Out of Scope

- News stand index (stacked card UI) — separate spec
- Newspapers index page styling — handled in a later phase
- Multiple simultaneous overlays
- Story editing or creation in this view
- Mobile responsive layout
- Torn-edge clipping effects (deferred to V2)
- Test strategy (deferred)

## Phasing

This spec implements in three phases. Each phase ends in something visible and verifiable.

### Phase 3a — Design System Foundation

The contract. Tokens, typography, theme file structure, `Newspaper#slug`, body data attribute. After this phase, the existing edition show page renders in Pryce of Progress colors and fonts — no layout changes yet, but the theming is alive. Adding a future newspaper means one new file.

### Phase 3b — Edition Front Page Layout

The reading experience. Grid container, story spans per theme, masthead, attention bar, story partial, controller ordering by type, Story scopes. After this phase, the edition show page renders as a real newspaper front page with stories slotted by type. Validates the dense-packing layout against real story counts.

### Phase 3c — Overflow & Clipping Overlay

The interactive piece. Stimulus overflow detection, "Continued on page X" link, `StoriesController#show`, nested route, Turbo Frame in layout, Alpine.js overlay state, story clipping component. After this phase, overflowing stories show the continued link and clicking opens the overlay clipping.

Phase B will likely surface adjustments needed for Phase C (e.g. how `overflow: hidden` interacts with grid-controlled height). Phase B may also reshape some assumptions in this spec once the layout meets real data.
