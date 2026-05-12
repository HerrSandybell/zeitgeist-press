# Mobile Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Zeitgeist Press front page and story overlay usable on phones and tablets using a single `≤768px` breakpoint.

**Architecture:** All changes are `@media (max-width: 768px)` blocks appended to existing CSS files. The front-page grid switches from `display: grid` to `display: flex; flex-direction: column`, bypassing all theme `grid-column: span N` rules. Stories get a `max-height: 20rem` cap so the overflow Stimulus controller can still detect truncation. No Ruby, no JS, no new files beyond the test file.

**Tech Stack:** Rails 8 / Propshaft CSS pipeline / Capybara + Selenium (headless Chrome) system tests

---

## File Map

| File | Change |
|---|---|
| `app/assets/stylesheets/application.css` | Add missing `@import` for `story.css` and `story_overlay.css` |
| `app/assets/stylesheets/base/layout.css` | `≤768px`: full-bleed `.newspaper-page` |
| `app/assets/stylesheets/base/typography.css` | `≤768px`: zero `.page-content` padding; `white-space: normal` on `.masthead-title` |
| `app/assets/stylesheets/base/grid.css` | `≤768px`: flex column for `.front-page-grid` |
| `app/assets/stylesheets/components/story.css` | `≤768px`: `max-height: 20rem`; `column-count: 1` |
| `app/assets/stylesheets/components/story_overlay.css` | `≤768px`: remove rotation; `column-count: 1` in cutout |
| `app/assets/stylesheets/components/masthead.css` | `≤768px`: stack `.masthead-info`; allow title wrap |
| `test/system/mobile_layout_test.rb` | New — all mobile system tests |

---

## Task 1: CSS imports + page layout

**Background:** `story.css` and `story_overlay.css` are currently absent from `application.css`. Propshaft bundles only what is explicitly `@import`-ed, so those files may not be applied in production. Add them now (after the theme imports so their rules override theme rules at equal specificity). Then make the newspaper page fill the viewport edge-to-edge on mobile.

**Files:**
- Modify: `app/assets/stylesheets/application.css`
- Modify: `app/assets/stylesheets/base/layout.css`
- Modify: `app/assets/stylesheets/base/typography.css`
- Create: `test/system/mobile_layout_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/system/mobile_layout_test.rb`:

```ruby
require "application_system_test_case"

class MobileLayoutTest < ApplicationSystemTestCase
  MOBILE_WIDTH  = 375
  MOBILE_HEIGHT = 812

  setup do
    @edition    = editions(:one)
    @newspaper  = @edition.newspaper
    current_window.resize_to(MOBILE_WIDTH, MOBILE_HEIGHT)
    visit newspaper_edition_path(@newspaper, @edition)
  end

  teardown do
    current_window.resize_to(1400, 1400)
  end

  test "newspaper page fills the full viewport width on mobile" do
    page_width = page.evaluate_script(
      "document.querySelector('.newspaper-page').getBoundingClientRect().width"
    )
    viewport_width = page.evaluate_script("window.innerWidth")
    assert_equal viewport_width.to_i, page_width.to_i
  end

  test "page-content has no padding on mobile" do
    padding = page.evaluate_script(
      "window.getComputedStyle(document.querySelector('.page-content')).padding"
    )
    assert_equal "0px", padding
  end
end
```

- [ ] **Step 2: Run to confirm they fail**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 2 failures. The page will still have `max-width: 1100px` and `box-shadow`, and `.page-content` will still have its default padding.

- [ ] **Step 3: Add missing CSS imports to `application.css`**

Open `app/assets/stylesheets/application.css`. The current tail of the file is:

```css
@import "components/masthead.css";
@import "components/navbar.css";
@import "components/footer.css";
```

Replace it with:

```css
@import "components/masthead.css";
@import "components/navbar.css";
@import "components/story.css";
@import "components/story_overlay.css";
@import "components/footer.css";
```

- [ ] **Step 4: Add mobile block to `layout.css`**

Append to `app/assets/stylesheets/base/layout.css`:

```css
@media (max-width: 768px) {
  .newspaper-page {
    max-width: 100%;
    box-shadow: none;
  }
}
```

- [ ] **Step 5: Add mobile block to `typography.css`**

Append to `app/assets/stylesheets/base/typography.css`:

```css
@media (max-width: 768px) {
  .page-content {
    padding: 0;
  }

  .masthead-title {
    white-space: normal;
  }
}
```

- [ ] **Step 6: Run tests — expect pass**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 2 passes.

- [ ] **Step 7: Commit**

```bash
git add app/assets/stylesheets/application.css \
        app/assets/stylesheets/base/layout.css \
        app/assets/stylesheets/base/typography.css \
        test/system/mobile_layout_test.rb
git commit -m "feat(mobile): full-bleed page layout at ≤768px"
```

---

## Task 2: Single-column story grid

**Background:** At mobile width, the `.front-page-grid` must switch from `display: grid` (with 12 theme-defined columns) to `display: flex; flex-direction: column`. Using flex completely bypasses the `grid-column: span N` rules in the theme CSS — no theme file changes needed.

**Files:**
- Modify: `app/assets/stylesheets/base/grid.css`
- Modify: `test/system/mobile_layout_test.rb`

- [ ] **Step 1: Add failing test**

Append to the `MobileLayoutTest` class in `test/system/mobile_layout_test.rb`:

```ruby
test "story grid is a flex column on mobile" do
  display = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('.front-page-grid')).display"
  )
  flex_direction = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('.front-page-grid')).flexDirection"
  )
  assert_equal "flex", display
  assert_equal "column", flex_direction
end
```

- [ ] **Step 2: Run to confirm failure**

```bash
bin/rails test test/system/mobile_layout_test.rb:33
```

Expected: 1 failure. The grid still reports `display: grid`.

- [ ] **Step 3: Add mobile block to `grid.css`**

Append to `app/assets/stylesheets/base/grid.css`:

```css
@media (max-width: 768px) {
  .front-page-grid {
    display: flex;
    flex-direction: column;
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 3 passes.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/base/grid.css \
        test/system/mobile_layout_test.rb
git commit -m "feat(mobile): single-column flex story grid at ≤768px"
```

---

## Task 3: Story max-height and overflow

**Background:** On desktop, story height is constrained by the CSS Grid row (`grid-auto-rows: 20rem`), which lets the overflow Stimulus controller detect truncation via `scrollHeight > clientHeight`. With the grid removed on mobile, stories expand to full height and overflow is never detected — the "Continued" link never appears. Adding `max-height: 20rem` to `.story` restores the constraint. The `column-count` used by the theme for multi-column story bodies must also be reset to 1 on mobile.

The theme rules that set `column-count` (e.g. `[data-newspaper="pryce-of-progress"] .story--major .story-body { column-count: 3; }`) have specificity [0,3,0]. Since `story.css` is now imported after the theme files in `application.css`, using the same specificity with matching selectors works — later in source order wins at equal specificity.

**Files:**
- Modify: `app/assets/stylesheets/components/story.css`
- Modify: `test/system/mobile_layout_test.rb`

- [ ] **Step 1: Add failing tests**

Append to the `MobileLayoutTest` class:

```ruby
test "story cards are capped at 20rem on mobile" do
  max_height = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('.story')).maxHeight"
  )
  # 20rem = 320px at the default 16px root font size
  assert_equal "320px", max_height
end

test "long story shows the continued link on mobile" do
  long = stories(:long_major)
  assert_selector "article[data-story-id='#{long.id}'] a.story-continued-link",
                  visible: true, wait: 5
end

test "short story does not show the continued link on mobile" do
  short = stories(:tertiary_one)
  long  = stories(:long_major)
  # Wait for overflow detection to complete on the long story first
  assert_selector "article[data-story-id='#{long.id}'] a.story-continued-link",
                  visible: true, wait: 5
  within "article[data-story-id='#{short.id}']" do
    assert_no_selector "a.story-continued-link", visible: true
  end
end
```

- [ ] **Step 2: Run to confirm failures**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 3 new failures. The `max-height` is `none`, and the continued link on `long_major` is hidden because overflow can't be detected without a height constraint.

- [ ] **Step 3: Add mobile block to `story.css`**

Append to `app/assets/stylesheets/components/story.css`:

```css
@media (max-width: 768px) {
  .story {
    max-height: 20rem;
  }

  /* Reset multi-column text laid out by theme rules.
   * Selectors match theme specificity [0,3,0]; story.css loads after themes. */
  [data-newspaper] .story--major .story-body,
  [data-newspaper] .story--secondary .story-body {
    column-count: 1;
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 6 passes.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/components/story.css \
        test/system/mobile_layout_test.rb
git commit -m "feat(mobile): cap story height at 20rem; restore overflow detection"
```

---

## Task 4: Story overlay mobile fixes

**Background:** The story overlay (`.story-cutout`) has a slight `rotate()` transform that looks awkward on phones and a 3-column layout for story body text. Both need to be reset at mobile widths.

The selector `[data-newspaper].story-cutout .story .story-body` from the existing overlay CSS has specificity [0,4,0]. The mobile override uses the same selector inside a media query appended to the same file, so it wins by source order.

**Files:**
- Modify: `app/assets/stylesheets/components/story_overlay.css`
- Modify: `test/system/mobile_layout_test.rb`

- [ ] **Step 1: Add failing tests**

Append to the `MobileLayoutTest` class:

```ruby
test "story overlay cutout has no rotation on mobile" do
  long = stories(:long_major)
  within "article[data-story-id='#{long.id}']" do
    assert_selector "a.story-continued-link", visible: true, wait: 5
    find("a.story-continued-link").click
  end
  assert_selector ".overlay-frame--open", wait: 5

  transform = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('article.story-cutout')).transform"
  )
  # CSS 'transform: none' computes to 'none' or the identity matrix
  assert_includes ["none", "matrix(1, 0, 0, 1, 0, 0)"], transform
end

test "story overlay cutout body is single-column on mobile" do
  long = stories(:long_major)
  within "article[data-story-id='#{long.id}']" do
    assert_selector "a.story-continued-link", visible: true, wait: 5
    find("a.story-continued-link").click
  end
  assert_selector ".overlay-frame--open", wait: 5

  col_count = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('[data-newspaper] .story-cutout .story .story-body')).columnCount"
  )
  assert_equal "1", col_count
end
```

- [ ] **Step 2: Run to confirm failures**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 2 new failures. The cutout will show a rotated, multi-column layout.

- [ ] **Step 3: Add mobile block to `story_overlay.css`**

Append to `app/assets/stylesheets/components/story_overlay.css`:

```css
@media (max-width: 768px) {
  .story-cutout,
  .story-cutout--secondary,
  .story-cutout--tertiary,
  .story-cutout--advertisement {
    transform: none;
  }

  /* Same specificity as the desktop rule above; wins by source order. */
  [data-newspaper].story-cutout .story .story-body {
    column-count: 1;
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 8 passes.

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/components/story_overlay.css \
        test/system/mobile_layout_test.rb
git commit -m "feat(mobile): remove overlay rotation and reset column count"
```

---

## Task 5: Masthead mobile treatment

**Background:** The `.masthead-info` bar uses `grid-template-columns: 1fr 2fr 1fr` to show volume, date, and print location side by side. On a 375px screen those columns are too narrow. It should stack as a single centered column. The `.masthead-title` already uses `font-size: clamp(2rem, 6vw, 4.5rem)` but has `white-space: nowrap` (set in `typography.css`) which will overflow the viewport on long newspaper names — already reset in Task 1's `typography.css` block.

**Files:**
- Modify: `app/assets/stylesheets/components/masthead.css`
- Modify: `test/system/mobile_layout_test.rb`

- [ ] **Step 1: Add failing tests**

Append to the `MobileLayoutTest` class:

```ruby
test "masthead info bar stacks in a single column on mobile" do
  col_count = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('.masthead-info')).gridTemplateColumns.split(' ').length"
  )
  assert_equal 1, col_count
end

test "masthead title wraps rather than overflowing on mobile" do
  white_space = page.evaluate_script(
    "window.getComputedStyle(document.querySelector('.masthead-title')).whiteSpace"
  )
  assert_equal "normal", white_space
end
```

- [ ] **Step 2: Run to confirm failures**

```bash
bin/rails test test/system/mobile_layout_test.rb
```

Expected: 2 new failures. The info bar still shows 3 columns. (The `white-space` test may already pass if Task 1 was implemented correctly; if so, that's fine — a passing test that was already passing is not a problem.)

- [ ] **Step 3: Add mobile block to `masthead.css`**

Append to `app/assets/stylesheets/components/masthead.css`:

```css
@media (max-width: 768px) {
  .masthead-info {
    grid-template-columns: 1fr;
  }

  .masthead-info__vol,
  .masthead-info__date,
  .masthead-info__location {
    text-align: center;
  }
}
```

- [ ] **Step 4: Run the full test suite**

```bash
bin/rails test
```

Expected: all tests pass, including the existing `StoryOverflowTest` suite (which runs at 1400px and should be unaffected).

- [ ] **Step 5: Commit**

```bash
git add app/assets/stylesheets/components/masthead.css \
        test/system/mobile_layout_test.rb
git commit -m "feat(mobile): stack masthead info bar in single column"
```

---

## Verification

After all tasks are complete, do a manual check in a browser:

1. Open the app in Chrome DevTools with device emulation set to iPhone SE (375×667).
2. Confirm stories stack vertically, fill the screen edge-to-edge, and are capped in height with the continued link visible on the long dispatch story.
3. Click "Continued on page #" — the overlay should open without rotation and display the full story in a single column.
4. Check the masthead: the newspaper name should wrap if long, and the vol/date/location should stack.
5. Run `bin/rails test` one final time and confirm all green.
