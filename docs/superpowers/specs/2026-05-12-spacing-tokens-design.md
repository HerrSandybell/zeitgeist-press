# Spacing Token System — Design Spec

**Date:** 2026-05-12
**Scope:** `app/assets/stylesheets/` — base, components (excluding navbar)
**Type:** Pure refactor — no visual changes intended

---

## Problem

Spacing values (margin, padding) are hard-coded throughout the stylesheets with no consistent scale. 15 distinct values appear across 6 files, many repeated but unconnected. There is no shared language for "how much space is this?", making future theme work and maintenance harder.

The existing `tokens.css` already establishes a token contract for color, typography, and layout — but spacing is absent.

---

## Decision

Add 6 spacing tokens to `tokens.css` on a 0.25rem grid (Tailwind-style numeric naming). Replace all occurrences of scale-aligned values throughout the stylesheets. Leave genuinely bespoke values as hard-coded numbers.

---

## The Scale

```css
/* tokens.css — Spacing */
--space-1:  0.25rem;   /*  4px */
--space-2:  0.5rem;    /*  8px */
--space-3:  0.75rem;   /* 12px */
--space-4:  1rem;      /* 16px */
--space-6:  1.5rem;    /* 24px */
--space-8:  2rem;      /* 32px */
```

Numbers correspond to multiples of 0.25rem, matching the Tailwind convention. Steps 5 and 7 are intentionally omitted — no values in the codebase require them.

---

## File-by-File Changes

### `base/tokens.css`
Add the 6 spacing tokens under a new `/* Spacing */` section. Note: `--space-6` (1.5rem) shares its value with the existing `--column-gap` token. These are semantically distinct — `--column-gap` is a layout structural token, `--space-6` is a spacing scale step. Do not merge or replace one with the other.

### `base/typography.css`
| Before | After |
|--------|-------|
| `.page-content { padding: 2rem 1rem; }` | `padding: var(--space-8) var(--space-4)` |

Em-based margins on `h1–h6`, `p` stay as `em` — they scale with font-size intentionally.

### `base/grid.css`
| Before | After |
|--------|-------|
| `.front-page-grid { padding: 0 1rem 2rem; }` | `padding: 0 var(--space-4) var(--space-8)` |
| `.advertisements-grid { padding-top: 1rem; }` | `padding-top: var(--space-4)` |
| `.advertisements-grid { margin-top: -1rem; }` | `margin-top: calc(var(--space-4) * -1)` |

### `components/masthead.css`
| Before | After |
|--------|-------|
| `.masthead { padding: 1rem 1rem 0; }` | `padding: var(--space-4) var(--space-4) 0` |
| `.masthead { margin-bottom: 1.5rem; }` | `margin-bottom: var(--space-6)` |
| `.masthead-meta { padding-bottom: 0.5rem; }` | `padding-bottom: var(--space-2)` |
| `.masthead-price { padding: 0.1rem 0.5rem; }` | `padding: 0.1rem var(--space-2)` |
| `.masthead-tagline { margin: 0.25rem 0 0.5rem; }` | `margin: var(--space-1) 0 var(--space-2)` |
| `.masthead-info { margin: 0.75rem 0; }` | `margin: var(--space-3) 0` |
| `.attention-bar { padding: 0.4rem 1rem; }` | `padding: 0.4rem var(--space-4)` |

Hard-coded values that remain: `0.1rem` (price pip), `0.3rem` (info bar padding), `0.4rem` (attention bar top/bottom).

### `components/story.css`
| Before | After |
|--------|-------|
| `.story { padding: 1rem 1rem 2rem; }` | `padding: var(--space-4) var(--space-4) var(--space-8)` |
| `.story-quote { padding-left: 1rem; }` | `padding-left: var(--space-4)` |
| `.story-continued-link { bottom: 0.5rem; }` | `bottom: var(--space-2)` |
| `.story-continued-link { right: 0.75rem; }` | `right: var(--space-3)` |

Hard-coded values that remain: `4.5rem` fade gradient height (structural, tied to `--grid-row-unit`). Em-based margins on `.story-subtitle`, `.story-ticker`, `.story-quote`, and `cite` stay as `em`.

### `components/story_overlay.css`
| Before | After |
|--------|-------|
| `.overlay-frame { padding: 2rem 1rem; }` | `padding: var(--space-8) var(--space-4)` |
| `.story-cutout { padding: 1.5rem 2rem; }` | `padding: var(--space-6) var(--space-8)` |
| `.story-cutout__masthead { padding-bottom: 0.5rem; }` | `padding-bottom: var(--space-2)` |
| `.story-cutout__masthead { margin-bottom: 0.75rem; }` | `margin-bottom: var(--space-3)` |
| `.story-cutout__footer { padding-top: 0.5rem; }` | `padding-top: var(--space-2)` |
| `.story-cutout__footer { margin-top: 1rem; }` | `margin-top: var(--space-4)` |

### `components/footer.css`
| Before | After |
|--------|-------|
| `.site-footer { margin-top: 2rem; }` | `margin-top: var(--space-8)` |

---

## Out of Scope

- **`components/navbar.css`** — excluded by design; navbar is intentionally outside the theme system.
- **Font sizes and letter-spacing** — not in scope for this pass.
- **Color token gaps** — not in scope for this pass.
- **`base/layout.css`** — already uses tokens; no spacing changes needed.
- **Theme files** — grid/layout tokens already in theme files; no spacing changes needed.

---

## Constraints

- No new CSS classes, no structural changes, no visual differences.
- `em` values on typographic elements stay as `em` — they are intentional, not a gap.
- The 6-step scale intentionally omits steps 5 and 7; add them only when a real use case exists.
- Navbar color hard-coding is a known deviation, accepted as out of scope.

---

## Success Criteria

- All 6 tokens defined in `tokens.css`.
- No `rem` spacing value from the "replaces" table remains hard-coded in the target files.
- App renders identically before and after (visual regression check: load the front page and overlay in a browser).
- No new hard-coded values introduced.
