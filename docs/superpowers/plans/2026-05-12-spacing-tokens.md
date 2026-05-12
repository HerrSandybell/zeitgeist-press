# Spacing Token System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all hard-coded rem spacing values in the stylesheets with CSS custom property tokens on a consistent 0.25rem numeric scale.

**Architecture:** Add 6 spacing tokens to `base/tokens.css`, then do a targeted find-and-replace pass across 6 component/base files. This is a pure refactor — no new classes, no structural changes, no visual differences. `em`-based margins on typographic elements are intentional and stay untouched.

**Tech Stack:** CSS custom properties (no build step, no preprocessor — Propshaft serves files as-is)

---

## Files Modified

| File | Change |
|------|--------|
| `app/assets/stylesheets/base/tokens.css` | Add `/* Spacing */` section with 6 tokens |
| `app/assets/stylesheets/base/typography.css` | 1 replacement |
| `app/assets/stylesheets/base/grid.css` | 3 replacements |
| `app/assets/stylesheets/components/masthead.css` | 7 replacements |
| `app/assets/stylesheets/components/story.css` | 4 replacements |
| `app/assets/stylesheets/components/story_overlay.css` | 6 replacements |
| `app/assets/stylesheets/components/footer.css` | 1 replacement |

**Not touched:** `navbar.css` (intentionally outside the token system), `layout.css` (already uses tokens), theme files (no spacing hard-codes).

---

## Task 1: Add spacing tokens to `tokens.css`

**Files:**
- Modify: `app/assets/stylesheets/base/tokens.css`

- [ ] **Step 1: Open the file and locate the `/* Layout */` block**

The file currently ends after the `/* Layout */` section. Add a new `/* Spacing */` section after it. The full file after the edit:

```css
/*
 * Design tokens — the theme contract.
 * Every per-newspaper theme overrides these via [data-newspaper="<slug>"].
 * Defaults here are neutral so pages without a theme still render legibly.
 */

:root {
  /* Color */
  --color-paper:      #ffffff;
  --color-ink:        #000000;
  --color-ink-muted:  #555555;
  --color-rule:       #000000;
  --color-accent:     #000000;

  /* Typography */
  --font-masthead:    serif;
  --font-headline:    serif;
  --font-body:        serif;

  /* Layout */
  --rule-width:       1px;
  --column-gap:       1.5rem;
  --grid-row-unit:    auto;
  --grid-columns:     4;
  --page-width:       1200px;
  --color-background: #d0d0d0;

  /* Spacing — 0.25rem grid (Tailwind-style numeric scale) */
  --space-1:          0.25rem;   /*  4px */
  --space-2:          0.5rem;    /*  8px */
  --space-3:          0.75rem;   /* 12px */
  --space-4:          1rem;      /* 16px */
  --space-6:          1.5rem;    /* 24px */
  --space-8:          2rem;      /* 32px */
}
```

Note: `--space-6` shares its value with `--column-gap` — they are semantically distinct. Do not merge them.

- [ ] **Step 2: Start the dev server and confirm the page still loads**

```bash
bin/dev
```

Open `http://localhost:3000`. The front page should look identical to before — adding tokens to `:root` with no usages yet changes nothing visually. If the page fails to load, check for a syntax error in `tokens.css`.

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/base/tokens.css
git commit -m "feat(tokens): add 6-step spacing scale to design tokens"
```

---

## Task 2: Update `base/typography.css`

**Files:**
- Modify: `app/assets/stylesheets/base/typography.css`

- [ ] **Step 1: Replace the `.page-content` padding value**

Find this rule (line 17–19):
```css
.page-content {
  padding: 2rem 1rem;
}
```

Replace with:
```css
.page-content {
  padding: var(--space-8) var(--space-4);
}
```

- [ ] **Step 2: Verify nothing else needs changing in this file**

The remaining spacing values in `typography.css` are all `em`-based (`0 0 0.5em`, `0 0 1em`) — these are intentional because they scale with the element's own font-size. Leave them untouched.

- [ ] **Step 3: Check the page visually**

Reload `http://localhost:3000`. Page content area padding should look identical.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/base/typography.css
git commit -m "refactor(typography): replace hard-coded padding with spacing tokens"
```

---

## Task 3: Update `base/grid.css`

**Files:**
- Modify: `app/assets/stylesheets/base/grid.css`

- [ ] **Step 1: Replace spacing values in `.front-page-grid`**

Find:
```css
.front-page-grid {
  display: grid;
  grid-template-columns: repeat(var(--grid-columns), 1fr);
  grid-auto-rows: var(--grid-row-unit);
  gap: var(--column-gap);
  padding: 0 1rem 2rem;
}
```

Replace with:
```css
.front-page-grid {
  display: grid;
  grid-template-columns: repeat(var(--grid-columns), 1fr);
  grid-auto-rows: var(--grid-row-unit);
  gap: var(--column-gap);
  padding: 0 var(--space-4) var(--space-8);
}
```

- [ ] **Step 2: Replace spacing values in `.advertisements-grid`**

Find:
```css
.advertisements-grid {
  border-top: calc(var(--rule-width) * 3) double var(--color-rule);
  padding-top: 1rem;
  margin-top: -1rem;
}
```

Replace with:
```css
.advertisements-grid {
  border-top: calc(var(--rule-width) * 3) double var(--color-rule);
  padding-top: var(--space-4);
  margin-top: calc(-1 * var(--space-4));
}
```

- [ ] **Step 3: Check the page visually**

Reload `http://localhost:3000`. The front-page grid and advertisement section spacing should look identical.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/base/grid.css
git commit -m "refactor(grid): replace hard-coded spacing with tokens"
```

---

## Task 4: Update `components/masthead.css`

**Files:**
- Modify: `app/assets/stylesheets/components/masthead.css`

- [ ] **Step 1: Replace spacing in `.masthead`**

Find:
```css
.masthead {
  padding: 1rem 1rem 0;
  text-align: center;
  border-bottom: calc(var(--rule-width) * 3) double var(--color-rule);
  margin-bottom: 1.5rem;
}
```

Replace with:
```css
.masthead {
  padding: var(--space-4) var(--space-4) 0;
  text-align: center;
  border-bottom: calc(var(--rule-width) * 3) double var(--color-rule);
  margin-bottom: var(--space-6);
}
```

- [ ] **Step 2: Replace spacing in `.masthead-meta`**

Find:
```css
.masthead-meta {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  font-family: var(--font-body);
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  padding-bottom: 0.5rem;
}
```

Replace with:
```css
.masthead-meta {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  font-family: var(--font-body);
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  padding-bottom: var(--space-2);
}
```

- [ ] **Step 3: Replace spacing in `.masthead-price`**

Find:
```css
.masthead-price {
  background: var(--color-ink);
  color: var(--color-paper);
  padding: 0.1rem 0.5rem;
}
```

Replace with:
```css
.masthead-price {
  background: var(--color-ink);
  color: var(--color-paper);
  padding: 0.1rem var(--space-2);
}
```

The `0.1rem` top/bottom stays — it's a bespoke micro-adjustment for the price pill.

- [ ] **Step 4: Replace spacing in `.masthead-tagline`**

Find:
```css
.masthead-tagline {
  font-family: var(--font-body);
  font-style: italic;
  font-size: 0.875rem;
  color: var(--color-ink-muted);
  margin: 0.25rem 0 0.5rem;
  letter-spacing: 0.03em;
}
```

Replace with:
```css
.masthead-tagline {
  font-family: var(--font-body);
  font-style: italic;
  font-size: 0.875rem;
  color: var(--color-ink-muted);
  margin: var(--space-1) 0 var(--space-2);
  letter-spacing: 0.03em;
}
```

- [ ] **Step 5: Replace spacing in `.masthead-info`**

Find:
```css
.masthead-info {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  font-family: var(--font-body);
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  border-top: var(--rule-width) solid var(--color-rule);
  border-bottom: var(--rule-width) solid var(--color-rule);
  padding: 0.3rem 0;
  margin: 0.75rem 0;
}
```

Replace with:
```css
.masthead-info {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  font-family: var(--font-body);
  font-size: 0.7rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  border-top: var(--rule-width) solid var(--color-rule);
  border-bottom: var(--rule-width) solid var(--color-rule);
  padding: 0.3rem 0;
  margin: var(--space-3) 0;
}
```

The `0.3rem` vertical padding stays — it's a bespoke value for the compact info bar.

- [ ] **Step 6: Replace spacing in `.attention-bar`**

Find:
```css
.attention-bar {
  font-family: var(--font-body);
  font-weight: bold;
  text-align: center;
  padding: 0.4rem 1rem;
  margin: 0 -1rem;
  background: var(--color-ink);
  color: var(--color-paper);
  letter-spacing: 0.08em;
  font-size: 0.875rem;
}
```

Replace with:
```css
.attention-bar {
  font-family: var(--font-body);
  font-weight: bold;
  text-align: center;
  padding: 0.4rem var(--space-4);
  margin: 0 calc(-1 * var(--space-4));
  background: var(--color-ink);
  color: var(--color-paper);
  letter-spacing: 0.08em;
  font-size: 0.875rem;
}
```

The `0.4rem` vertical padding stays — bespoke for the attention bar height.

- [ ] **Step 7: Check the masthead visually**

Reload `http://localhost:3000`. The masthead section (title, meta row, date/vol bar, attention bar) should look identical.

- [ ] **Step 8: Commit**

```bash
git add app/assets/stylesheets/components/masthead.css
git commit -m "refactor(masthead): replace hard-coded spacing with tokens"
```

---

## Task 5: Update `components/story.css`

**Files:**
- Modify: `app/assets/stylesheets/components/story.css`

- [ ] **Step 1: Replace spacing in `.story`**

Find:
```css
.story {
  padding: 1rem 1rem 2rem;
  border-top: var(--rule-width) solid var(--color-rule);
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
```

Replace with:
```css
.story {
  padding: var(--space-4) var(--space-4) var(--space-8);
  border-top: var(--rule-width) solid var(--color-rule);
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}
```

- [ ] **Step 2: Replace spacing in `.story-quote`**

Find:
```css
.story-quote {
  font-family: var(--font-headline);
  font-size: 1.25rem;
  font-style: italic;
  border-left: calc(var(--rule-width) * 3) solid var(--color-accent);
  padding-left: 1rem;
  margin: 1em 0;
  color: var(--color-ink);
}
```

Replace with:
```css
.story-quote {
  font-family: var(--font-headline);
  font-size: 1.25rem;
  font-style: italic;
  border-left: calc(var(--rule-width) * 3) solid var(--color-accent);
  padding-left: var(--space-4);
  margin: 1em 0;
  color: var(--color-ink);
}
```

The `margin: 1em 0` stays — it's `em`-based intentionally (scales with the quote's font-size).

- [ ] **Step 3: Replace spacing in `.story-continued-link`**

Find:
```css
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
```

Replace with:
```css
.story-continued-link {
  position: absolute;
  bottom: var(--space-2);
  right: var(--space-3);
  font-family: var(--font-body);
  font-style: italic;
  font-size: 0.85rem;
  color: var(--color-accent);
  text-decoration: none;
  z-index: 1;
}
```

- [ ] **Step 4: Check stories visually**

Reload `http://localhost:3000`. Story cards, pull quotes, and "Continued on page #" link positions should look identical.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/components/story.css
git commit -m "refactor(story): replace hard-coded spacing with tokens"
```

---

## Task 6: Update `components/story_overlay.css`

**Files:**
- Modify: `app/assets/stylesheets/components/story_overlay.css`

- [ ] **Step 1: Replace spacing in `.overlay-frame`**

Find:
```css
.overlay-frame {
  position: fixed;
  inset: 0;
  background: rgba(20, 15, 10, 0);
  pointer-events: none;
  transition: background 200ms ease;
  z-index: 100;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  overflow-y: auto;
  padding: 2rem 1rem;
}
```

Replace with:
```css
.overlay-frame {
  position: fixed;
  inset: 0;
  background: rgba(20, 15, 10, 0);
  pointer-events: none;
  transition: background 200ms ease;
  z-index: 100;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  overflow-y: auto;
  padding: var(--space-8) var(--space-4);
}
```

- [ ] **Step 2: Replace spacing in `.story-cutout`**

Find:
```css
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
```

Replace with:
```css
.story-cutout {
  background: var(--color-paper);
  color: var(--color-ink);
  font-family: var(--font-body);
  padding: var(--space-6) var(--space-8);
  border: 1px solid var(--color-rule);
  box-shadow: 3px 4px 24px rgba(0, 0, 0, 0.5),
              0 1px 4px rgba(0, 0, 0, 0.3);
  transform: rotate(-0.8deg);
}
```

- [ ] **Step 3: Replace spacing in `.story-cutout__masthead`**

Find:
```css
.story-cutout__masthead {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-accent);
  border-bottom: 1px solid var(--color-rule);
  padding-bottom: 0.5rem;
  margin-bottom: 0.75rem;
}
```

Replace with:
```css
.story-cutout__masthead {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  color: var(--color-accent);
  border-bottom: 1px solid var(--color-rule);
  padding-bottom: var(--space-2);
  margin-bottom: var(--space-3);
}
```

- [ ] **Step 4: Replace spacing in `.story-cutout__footer`**

Find:
```css
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

Replace with:
```css
.story-cutout__footer {
  font-size: 0.75rem;
  font-style: italic;
  color: var(--color-ink-muted);
  text-align: right;
  border-top: 1px solid var(--color-rule);
  padding-top: var(--space-2);
  margin-top: var(--space-4);
}
```

- [ ] **Step 5: Check the overlay visually**

Click a "Continued on page #" link on the front page. The overlay backdrop and cutout card should look identical to before.

- [ ] **Step 6: Commit**

```bash
git add app/assets/stylesheets/components/story_overlay.css
git commit -m "refactor(story-overlay): replace hard-coded spacing with tokens"
```

---

## Task 7: Update `components/footer.css`

**Files:**
- Modify: `app/assets/stylesheets/components/footer.css`

- [ ] **Step 1: Replace spacing in `.site-footer`**

Find:
```css
.site-footer {
  border-top: var(--rule-width) solid var(--color-rule);
  margin-top: 2rem;
}
```

Replace with:
```css
.site-footer {
  border-top: var(--rule-width) solid var(--color-rule);
  margin-top: var(--space-8);
}
```

- [ ] **Step 2: Check the footer visually**

Reload `http://localhost:3000`. Scroll to the bottom — the footer spacing should look identical.

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/components/footer.css
git commit -m "refactor(footer): replace hard-coded spacing with tokens"
```

---

## Task 8: Final verification

- [ ] **Step 1: Confirm no hard-coded rem spacing values remain in target files**

```bash
grep -n "\b[0-9]\+\(\.[0-9]\+\)\?rem" \
  app/assets/stylesheets/base/typography.css \
  app/assets/stylesheets/base/grid.css \
  app/assets/stylesheets/components/masthead.css \
  app/assets/stylesheets/components/story.css \
  app/assets/stylesheets/components/story_overlay.css \
  app/assets/stylesheets/components/footer.css
```

Expected matches (these are intentional hard-codes — anything else is a miss):

| File | Value | Reason |
|------|-------|--------|
| `masthead.css` | `0.1rem` | Price pip top/bottom micro-adjustment |
| `masthead.css` | `0.3rem` | Info bar vertical padding |
| `masthead.css` | `0.4rem` | Attention bar vertical padding |
| `story.css` | `4.5rem` | Fade gradient height (tied to grid-row-unit) |
| `story_overlay.css` | `min(90vw, 56rem)` | Max-width clamp — not a spacing value |

If any other `rem` values appear, replace them with their appropriate token.

- [ ] **Step 2: Full visual pass in browser**

With `bin/dev` running:
1. Visit `http://localhost:3000` — check masthead, story grid, footer
2. Click a "Continued on page #" link — check overlay padding and cutout card
3. Scroll through the full page — no layout shifts or spacing regressions

- [ ] **Step 3: Run the test suite**

```bash
bin/rails test
```

Expected: all tests pass (this refactor touches no Ruby or HTML).

- [ ] **Step 4: Done**

All 6 tokens are defined. All target spacing values are tokenized. The codebase now has a shared spacing language for future work.
