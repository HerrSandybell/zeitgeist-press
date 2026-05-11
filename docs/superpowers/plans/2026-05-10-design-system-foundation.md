# Phase 3a — Design System Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the CSS design system foundation — semantic tokens, base typography, and the Pryce of Progress theme — so that the existing edition show page renders in Pryce of Progress's aged-newsprint colors and yellow-rag typography. No layout work yet.

**Architecture:** Semantic CSS custom properties declared in `base/tokens.css` form the theme contract. Each newspaper's theme file (`themes/<slug>.css`) overrides those tokens via a `[data-newspaper="<slug>"]` selector. The application layout stamps the current newspaper's slug onto `<body>`. Propshaft serves every CSS file in `app/assets/stylesheets/` — themes are scoped by selector, not by conditional file loading. Adding a future newspaper means adding one file in `themes/`.

**Tech Stack:** Rails 8.1, Propshaft, vanilla CSS with custom properties and `@import`, Google Fonts via CDN, Minitest.

**Reference spec:** `docs/superpowers/specs/2026-05-10-design-system-edition-view-design.md`

---

## File Map

- Create: `app/assets/stylesheets/base/tokens.css` — token contract
- Create: `app/assets/stylesheets/base/typography.css` — body, heading, and shared role styles
- Create: `app/assets/stylesheets/themes/pryce_of_progress.css` — Pryce theme + Google Fonts import
- Create: `app/assets/stylesheets/components/.keep` — reserved for Phase 3b/3c
- Modify: `app/assets/stylesheets/application.css` — replace placeholder comment with `@import` statements
- Modify: `app/models/newspaper.rb` — add `slug` method
- Modify: `app/views/layouts/application.html.erb` — stamp `data-newspaper` onto `<body>`
- Modify: `test/models/newspaper_test.rb` — add slug tests

---

### Task 1: Create the CSS directory structure

**Files:**
- Create: `app/assets/stylesheets/base/.keep`
- Create: `app/assets/stylesheets/themes/.keep`
- Create: `app/assets/stylesheets/components/.keep`

- [ ] **Step 1: Create the three subdirectories with placeholder files**

```bash
mkdir -p app/assets/stylesheets/base \
         app/assets/stylesheets/themes \
         app/assets/stylesheets/components
touch app/assets/stylesheets/base/.keep \
      app/assets/stylesheets/themes/.keep \
      app/assets/stylesheets/components/.keep
```

- [ ] **Step 2: Verify the structure**

Run:
```bash
ls app/assets/stylesheets/
```

Expected output:
```
application.css  base/  components/  themes/
```

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/base/.keep \
        app/assets/stylesheets/themes/.keep \
        app/assets/stylesheets/components/.keep
git commit -m "chore(css): scaffold design system directory structure"
```

---

### Task 2: Create the token contract — `base/tokens.css`

**Files:**
- Create: `app/assets/stylesheets/base/tokens.css`
- Delete: `app/assets/stylesheets/base/.keep`

- [ ] **Step 1: Write `app/assets/stylesheets/base/tokens.css`**

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
}
```

- [ ] **Step 2: Remove the no-longer-needed placeholder**

```bash
rm app/assets/stylesheets/base/.keep
```

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/base/
git commit -m "feat(css): add design token contract"
```

---

### Task 3: Create base typography — `base/typography.css`

**Files:**
- Create: `app/assets/stylesheets/base/typography.css`

- [ ] **Step 1: Write `app/assets/stylesheets/base/typography.css`**

```css
/*
 * Base typography. Applies the design tokens to HTML elements and shared
 * role classes. Theme files override the underlying tokens — these rules
 * stay constant across newspapers.
 */

body {
  font-family: var(--font-body);
  color: var(--color-ink);
  background-color: var(--color-paper);
  line-height: 1.6;
  margin: 0;
}

h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-headline);
  color: var(--color-ink);
  margin: 0 0 0.5em;
  line-height: 1.2;
}

p {
  margin: 0 0 1em;
}

a {
  color: var(--color-ink);
  text-decoration: underline;
}

/* Shared typographic roles — used by views in later phases. */

.masthead-title {
  font-family: var(--font-masthead);
  font-size: 4rem;
  text-align: center;
  margin: 0;
}

.attention-bar {
  font-family: var(--font-headline);
  color: var(--color-accent);
  font-weight: bold;
  text-align: center;
  padding: 0.5rem 1rem;
  border-top: var(--rule-width) solid var(--color-rule);
  border-bottom: var(--rule-width) solid var(--color-rule);
}

.headline--major     { font-size: 3rem;   line-height: 1.1;  }
.headline--secondary { font-size: 2rem;   line-height: 1.2;  }
.headline--tertiary  { font-size: 1.5rem; line-height: 1.25; }

.story-supertitle {
  font-family: var(--font-body);
  font-size: 0.875rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--color-ink-muted);
}

.story-body {
  font-family: var(--font-body);
  font-size: 1rem;
  line-height: 1.6;
  text-align: justify;
}

.story-byline {
  font-family: var(--font-body);
  font-style: italic;
  color: var(--color-ink-muted);
  font-size: 0.875rem;
}
```

- [ ] **Step 2: Commit**

```bash
git add app/assets/stylesheets/base/typography.css
git commit -m "feat(css): add base typography and shared role classes"
```

---

### Task 4: Create the Pryce of Progress theme

**Files:**
- Create: `app/assets/stylesheets/themes/pryce_of_progress.css`
- Delete: `app/assets/stylesheets/themes/.keep`

- [ ] **Step 1: Write `app/assets/stylesheets/themes/pryce_of_progress.css`**

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
}
```

- [ ] **Step 2: Remove the placeholder**

```bash
rm app/assets/stylesheets/themes/.keep
```

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/themes/
git commit -m "feat(css): add Pryce of Progress theme"
```

---

### Task 5: Wire stylesheets into the application manifest

The current `app/assets/stylesheets/application.css` contains only a Propshaft comment. We replace it with `@import` statements so the new files are served as one bundle through the layout's `stylesheet_link_tag :app`.

**Files:**
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Replace the contents of `app/assets/stylesheets/application.css`**

```css
/*
 * Application stylesheet — Propshaft manifest.
 * Order matters: tokens first (declares the contract),
 * then typography (uses the tokens),
 * then themes (override tokens per newspaper).
 */

@import "base/tokens.css";
@import "base/typography.css";
@import "themes/pryce_of_progress.css";
```

- [ ] **Step 2: Start the dev server in the background**

```bash
bin/dev
```

Wait a few seconds for it to boot. If port 3000 is already in use, stop the conflicting process first.

- [ ] **Step 3: Verify the manifest is served**

In another terminal:

```bash
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/assets/application.css
```

Expected: `200`.

If it returns 404, the layout's `stylesheet_link_tag :app` is not finding `application.css`. Investigate by inspecting the rendered HTML: `curl -s http://localhost:3000/ | grep -i stylesheet`. The `<link>` tag will show what path is being requested. If needed, modify `app/views/layouts/application.html.erb` to change `:app` to `"application"`.

- [ ] **Step 4: Stop the dev server**

Press Ctrl+C in the `bin/dev` terminal (or kill the process). The theme won't show visually until Task 7 — this step only verifies the asset pipeline is wired up.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/application.css
git commit -m "feat(css): wire base + theme stylesheets into application manifest"
```

---

### Task 6: Add `Newspaper#slug` with tests

The theme selector uses the newspaper slug. `name.parameterize` gives us `"Pryce of Progress"` → `"pryce-of-progress"` with no migration needed.

**Files:**
- Modify: `app/models/newspaper.rb`
- Modify: `test/models/newspaper_test.rb`

- [ ] **Step 1: Add two failing tests to `test/models/newspaper_test.rb`**

Append these tests inside the existing `NewspaperTest` class, before the final `end`:

```ruby
  test "slug parameterizes the name" do
    newspaper = Newspaper.new(name: "Pryce of Progress")
    assert_equal "pryce-of-progress", newspaper.slug
  end

  test "slug handles punctuation and ampersands" do
    newspaper = Newspaper.new(name: "The Times & Echo")
    assert_equal "the-times-echo", newspaper.slug
  end
```

- [ ] **Step 2: Run the tests — expect failure**

```bash
bin/rails test test/models/newspaper_test.rb
```

Expected: 2 errors with `NoMethodError: undefined method 'slug' for #<Newspaper ...>`. The three existing tests should still pass. Minitest reports this as `5 runs, 4 assertions, 0 failures, 2 errors, 0 skips`.

- [ ] **Step 3: Add the `slug` method**

Update `app/models/newspaper.rb` to:

```ruby
class Newspaper < ApplicationRecord
  has_many :editions, dependent: :destroy

  validates :name, presence: true

  def slug
    name.parameterize
  end
end
```

- [ ] **Step 4: Run the tests — expect pass**

```bash
bin/rails test test/models/newspaper_test.rb
```

Expected: `5 runs, 6 assertions, 0 failures, 0 errors, 0 skips`.

- [ ] **Step 5: Commit**

```bash
git add app/models/newspaper.rb test/models/newspaper_test.rb
git commit -m "feat(model): add Newspaper#slug for theme scoping"
```

---

### Task 7: Stamp `data-newspaper` onto `<body>` and verify the theme

**Files:**
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 1: Update the `<body>` tag in `app/views/layouts/application.html.erb`**

Find:

```erb
  <body>
    <%= yield %>
  </body>
```

Replace with:

```erb
  <body data-newspaper="<%= @edition&.newspaper&.slug %>">
    <%= yield %>
  </body>
```

The safe navigation operator (`&.`) ensures pages without an `@edition` (e.g. the newspapers index) render without raising — they get `data-newspaper=""` and fall through to the base token defaults.

- [ ] **Step 2: Start the dev server**

```bash
bin/dev
```

- [ ] **Step 3: Verify the theme activates on the edition show page**

Open `http://localhost:3000/newspapers/1/editions/1` in a browser.

Expected visual changes:
- Page background is aged newsprint (warm yellowish — `#f2e8c9`)
- Text color is dark brown (`#2c1810`)
- Headings render in **Alfa Slab One** (heavy slab serif)
- Body text renders in **Libre Baskerville** (period serif)
- In DevTools → Elements, the `<body>` tag shows `data-newspaper="pryce-of-progress"`
- In DevTools → Network, requests for `application.css`, `base/tokens.css`, `base/typography.css`, `themes/pryce_of_progress.css`, and the Google Fonts CSS all return 200

If the fonts don't load, check the Console for CSP violations on `fonts.googleapis.com` or `fonts.gstatic.com`. If blocked, you'll need to relax CSP in `config/initializers/content_security_policy.rb` to allow these hosts — but only do this if a violation is actually reported.

- [ ] **Step 4: Verify the newspapers index falls back to defaults**

Open `http://localhost:3000/`.

Expected:
- Background is white (no `--color-paper` override active)
- Text is black, default serif (`--font-body` is `serif`)
- In DevTools, `<body data-newspaper="">` — empty attribute value
- The page renders without errors

- [ ] **Step 5: Stop the dev server**

Press Ctrl+C.

- [ ] **Step 6: Run the full test suite**

```bash
bin/rails test
```

Expected: all tests pass. The new `data-newspaper` attribute doesn't break any existing tests because `@edition` is `nil` in any test that doesn't set it, and `nil&.newspaper&.slug` is `nil`, which renders as `data-newspaper=""`.

- [ ] **Step 7: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "feat(layout): stamp newspaper slug onto body for theme scoping"
```

---

## Definition of Done

After Task 7, opening `http://localhost:3000/newspapers/1/editions/1` in a browser shows the existing edition show page rendered in Pryce of Progress's aged-newsprint colors and yellow-rag fonts. The HTML structure has not changed — only the visual treatment. The newspapers index (`/`) still renders with default browser styling because no theme is scoped to it.

All Minitest tests pass.

Phase 3b (front page layout) will build on this foundation by adding the grid container, story partials, and per-theme story spans.
