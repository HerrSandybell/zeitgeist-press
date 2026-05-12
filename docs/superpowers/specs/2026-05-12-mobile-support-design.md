# Mobile Support Design

**Date:** 2026-05-12
**Status:** Approved
**Scope:** Responsive layout for Zeitgeist Press — makes the site usable on phones and tablets.

---

## Problem

The current layout is desktop-only. The front-page grid uses 12 fixed columns with `grid-auto-rows: 20rem`, and story spans (`grid-column: span 12`, `span 8`, `span 4`) assume a wide viewport. On screens narrower than the designed page width (~1100px), columns collapse to unusably narrow widths and text becomes illegible.

---

## Decisions

| Question | Decision |
|---|---|
| Mobile layout approach | Single-column editorial stack (stories full-width, stacked in order) |
| Story overflow on mobile | Cap each story card at `max-height: 20rem`; keep the "Continued" link and overlay |
| Page treatment on mobile | Full-bleed — newspaper page fills the viewport, no drop shadow or desk margins |
| Implementation strategy | Single `≤768px` breakpoint with token/layout overrides in existing CSS files |

---

## Design

### Breakpoint

One breakpoint: `max-width: 768px`. This covers all phones in portrait and landscape, small tablets, and iPad mini portrait. No intermediate tablet breakpoint.

### Page layout

At `≤768px`:
- `.newspaper-page` loses `box-shadow` and fills the viewport edge-to-edge (`max-width: 100%`). The "desk" background is no longer visible around the paper.
- `.page-content` padding (defined in `typography.css` as `var(--space-8) var(--space-4)`) is set to `0` on mobile so the newspaper page fills the screen.

### Story grid

At `≤768px`, `.front-page-grid` switches from `display: grid` to `display: flex; flex-direction: column`. Using flex (rather than overriding `--grid-columns`) sidesteps specificity conflicts with theme rules like `[data-newspaper="pryce-of-progress"] .story--major { grid-column: span 12; }` — flex simply ignores grid-column spans. Stories render in DOM order, which matches their `position` column (major first, then secondary, then tertiary).

The advertisements grid follows the same rule and stacks its ad cards vertically.

### Story overflow

At `≤768px`, each `.story` receives `max-height: 20rem`. This restores the height constraint that the overflow Stimulus controller relies on — it detects truncation by comparing `scrollHeight > clientHeight` on `.story-body`. With the grid row gone on mobile, without this cap no overflow is ever detected and the "Continued" link never appears.

Short stories that fit within 20rem show fully with no link. Long stories clip, show the fade gradient (`.story--overflows::after`), and show the "Continued on page #" link. No changes to `overflow_controller.js`.

### Multi-column text

Story bodies on the front page use `column-count: 2` or `column-count: 3` in theme CSS. At `≤768px`, `column-count` is reset to `1` for all `.story-body` elements — a single override block with `!important` if needed to beat the theme specificity.

### Story overlay (continued cutout)

The overlay already constrains itself to `max-width: min(90vw, 56rem)` so it fits narrow screens. Two mobile overrides are added:

1. **Rotation removed** — `.story-cutout` and its type variants have small `rotate()` transforms that look awkward on a phone. These are set to `rotate(0deg)` at `≤768px`.
2. **Column count reset** — The `[data-newspaper].story-cutout .story .story-body` rule forces 3-column layout in the cutout. At `≤768px` this resets to `column-count: 1`.

The overlay backdrop and scroll behaviour require no changes.

### Masthead

The `.masthead-info` bar uses `grid-template-columns: 1fr 2fr 1fr` to lay out volume/date/location side by side. At `≤768px` this switches to a single stacked column, center-aligned — all three spans become `text-align: center`.

The masthead title (`.masthead-title`) already uses `font-size: clamp(2rem, 6vw, 4.5rem)` so the size scales down on narrow screens. However, it also has `white-space: nowrap`, which causes long newspaper names (e.g. "THE PRYCE OF PROGRESS") to overflow on phones. At `≤768px`, `white-space` is overridden to `normal` so the title wraps across lines.

All other masthead elements (tagline, attention bar, edition meta) are already centered text and reflow naturally.

### Navbar

No changes required. The navbar is a small flex row with a label and select menu that already fits narrow screens.

---

## Files changed

All changes are additions to existing files. No new files are created.

| File | Change |
|---|---|
| `app/assets/stylesheets/base/layout.css` | `≤768px` block: remove page shadow, full-bleed page |
| `app/assets/stylesheets/base/typography.css` | `≤768px` block: remove `.page-content` padding; override `.masthead-title` `white-space: normal` |
| `app/assets/stylesheets/base/grid.css` | `≤768px` block: flex stack for `.front-page-grid` |
| `app/assets/stylesheets/components/story.css` | `≤768px` block: `max-height: 20rem`, reset `column-count: 1` |
| `app/assets/stylesheets/components/story_overlay.css` | `≤768px` block: remove rotation, reset overlay column-count |
| `app/assets/stylesheets/components/masthead.css` | `≤768px` block: stack masthead-info, cap title font-size |

Theme files (`broadsheet.css`, `pryce_of_progress.css`, `yellow_sheets.css`) require no changes — the flex override in grid.css makes their grid-column span rules irrelevant on mobile.

---

## Out of scope

- Tablet-specific intermediate layout (2-column grid at 768px–1100px)
- Per-story-type max-height variants on mobile
- Touch gesture support (swipe to dismiss overlay etc.)
- PWA / installable app behaviour
