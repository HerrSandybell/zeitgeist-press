# MVP Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a presentable front page — richer masthead, a Broadsheet visual theme, a minimal navbar/footer with a reusable select component, the edition as the site root, and an updated README.

**Architecture:** New nullable fields on `Newspaper` and `Edition` drive the masthead; a `ThemesController` stores the chosen theme in the session; `data-theme` on `<body>` activates a second CSS token block; three new ViewComponents (`SelectMenuComponent`, `NavbarComponent`, `FooterComponent`) slot into `application.html.erb`.

**Tech Stack:** Rails 8.1 / Minitest / ViewComponent / Stimulus / CSS custom properties / Propshaft

---

## File Map

| Action | File |
|---|---|
| Create | `db/migrate/TIMESTAMP_add_tagline_and_print_location_to_newspapers.rb` |
| Create | `db/migrate/TIMESTAMP_add_edition_type_and_price_and_city_to_editions.rb` |
| Modify | `test/fixtures/newspapers.yml` |
| Modify | `test/fixtures/editions.yml` |
| Modify | `db/seeds.rb` |
| Modify | `test/models/newspaper_test.rb` |
| Modify | `test/models/edition_test.rb` |
| Modify | `config/routes.rb` |
| Modify | `app/controllers/editions_controller.rb` |
| Modify | `test/controllers/editions_controller_test.rb` |
| Modify | `app/views/editions/_masthead.html.erb` |
| Modify | `app/assets/stylesheets/components/masthead.css` |
| Modify | `app/assets/stylesheets/base/typography.css` |
| Create | `app/assets/stylesheets/themes/broadsheet.css` |
| Modify | `app/assets/stylesheets/application.css` |
| Create | `app/controllers/themes_controller.rb` |
| Create | `test/controllers/themes_controller_test.rb` |
| Create | `app/javascript/controllers/theme_switcher_controller.js` |
| Create | `app/components/select_menu_component.rb` |
| Create | `app/components/select_menu_component.html.erb` |
| Create | `test/components/select_menu_component_test.rb` |
| Create | `app/components/navbar_component.rb` |
| Create | `app/components/navbar_component.html.erb` |
| Create | `app/assets/stylesheets/components/navbar.css` |
| Create | `test/components/navbar_component_test.rb` |
| Create | `app/components/footer_component.rb` |
| Create | `app/components/footer_component.html.erb` |
| Create | `app/assets/stylesheets/components/footer.css` |
| Create | `test/components/footer_component_test.rb` |
| Modify | `app/views/layouts/application.html.erb` |
| Modify | `README.md` |

---

## Task 1: Migrations — new fields on Newspaper and Edition

**Files:**
- Create: `db/migrate/TIMESTAMP_add_tagline_and_print_location_to_newspapers.rb`
- Create: `db/migrate/TIMESTAMP_add_edition_type_and_price_and_city_to_editions.rb`
- Modify: `test/models/newspaper_test.rb`
- Modify: `test/models/edition_test.rb`

- [ ] **Step 1: Write the failing model tests**

Add to `test/models/newspaper_test.rb` (inside the class, after existing tests):

```ruby
test "tagline is nil by default" do
  assert_nil Newspaper.new(name: "Test").tagline
end

test "print_location is nil by default" do
  assert_nil Newspaper.new(name: "Test").print_location
end
```

Add to `test/models/edition_test.rb` (inside the class, after existing tests):

```ruby
test "edition_type is nil by default" do
  assert_nil Edition.new.edition_type
end

test "price is nil by default" do
  assert_nil Edition.new.price
end

test "city is nil by default" do
  assert_nil Edition.new.city
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/models/newspaper_test.rb test/models/edition_test.rb
```

Expected: 5 failures — `NoMethodError: undefined method 'tagline'` (and similar).

- [ ] **Step 3: Generate and run migrations**

```bash
bin/rails generate migration AddTaglineAndPrintLocationToNewspapers tagline:string print_location:string
bin/rails generate migration AddEditionTypeAndPriceAndCityToEditions edition_type:string price:string city:string
bin/rails db:migrate
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
bin/rails test test/models/newspaper_test.rb test/models/edition_test.rb
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add db/migrate/ db/schema.rb test/models/newspaper_test.rb test/models/edition_test.rb
git commit -m "feat(model): add tagline, print_location, edition_type, price, city fields"
```

---

## Task 2: Update fixtures and seed data

**Files:**
- Modify: `test/fixtures/newspapers.yml`
- Modify: `test/fixtures/editions.yml`
- Modify: `db/seeds.rb`

The test strategy: `newspapers(:two)` and `editions(:two)` get all new fields populated (they are used for "full masthead" tests). `newspapers(:one)` and `editions(:one)` keep nil new fields (used for null-safety tests). `editions(:two)` is already `published: true` so `show_current` will find it.

- [ ] **Step 1: Update `test/fixtures/newspapers.yml`**

```yaml
one:
  name: Pryce of Progress

two:
  name: The Evening Post
  tagline: "All The News Worth Knowing"
  print_location: "Printed in Bosum Strand"
```

- [ ] **Step 2: Update `test/fixtures/editions.yml`**

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
  edition_type: "Extra Edition"
  price: "Two Pennies"
  city: "Flint"
```

- [ ] **Step 3: Update `db/seeds.rb`**

Find the lines that create the newspaper and edition. Replace them with an update-after-find pattern so the new fields are set on both fresh seeds AND re-seeds of an existing database.

Replace:

```ruby
newspaper = Newspaper.find_or_create_by!(name: "Pryce of Progress")

edition = newspaper.editions.find_or_create_by!(volume: 2, issue_number: 98) do |e|
  e.year           = 501
  e.season         = :spring
  e.day            = 10
  e.attention_bar  = "♦ The Workingman's Friend · Truth in Spite of Power · What the Tribune Won't Tell You ♦"
  e.published      = true
end
```

With:

```ruby
newspaper = Newspaper.find_or_create_by!(name: "Pryce of Progress")
newspaper.update!(
  tagline:        "What the Tribune Will Not Tell You — Twice a Week, Sometimes Thrice",
  print_location: "Printed in Bosum Strand"
)

edition = newspaper.editions.find_or_create_by!(volume: 2, issue_number: 98) do |e|
  e.year          = 501
  e.season        = :spring
  e.day           = 10
  e.attention_bar = "♦ The Workingman's Friend · Truth in Spite of Power · What the Tribune Won't Tell You ♦"
  e.published     = true
end
edition.update!(
  edition_type: "Extra Edition",
  price:        "Two Pennies",
  city:         "Flint"
)
```

- [ ] **Step 4: Run full test suite and seed**

```bash
bin/rails test
bin/rails db:seed
```

Expected: all existing tests pass, seed prints success message.

- [ ] **Step 5: Commit**

```bash
git add test/fixtures/newspapers.yml test/fixtures/editions.yml db/seeds.rb
git commit -m "feat(seeds): populate new masthead fields for Pryce of Progress"
```

---

## Task 3: Root route + EditionsController#show_current

**Files:**
- Modify: `config/routes.rb`
- Modify: `app/controllers/editions_controller.rb`
- Modify: `test/controllers/editions_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Add to `test/controllers/editions_controller_test.rb` (inside the class):

```ruby
test "show_current renders the first published edition at root" do
  get root_url
  assert_response :success
  assert_select "h1.masthead-title", text: editions(:two).newspaper.name
end

test "show_current returns 404 when no published edition exists" do
  Edition.update_all(published: false)
  get root_url
  assert_response :not_found
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/controllers/editions_controller_test.rb
```

Expected: FAIL — the root route currently renders `newspapers#index`, not the edition.

- [ ] **Step 3: Update `config/routes.rb`**

Replace:

```ruby
root "newspapers#index"
```

With:

```ruby
root "editions#show_current"
```

- [ ] **Step 4: Add `show_current` to `app/controllers/editions_controller.rb`**

```ruby
class EditionsController < ApplicationController
  def show
    @edition = Edition.includes(:newspaper).find(params[:id])
    load_stories
  end

  def show_current
    @edition = Edition.includes(:newspaper).where(published: true).order(:id).first!
    load_stories
    render :show
  end

  private

  def load_stories
    non_ads  = @edition.stories.where.not(story_type: :advertisement).order(:story_type, :position)
    ads      = @edition.stories.advertisement.order(:position).limit(4)
    @stories = non_ads + ads
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
bin/rails test test/controllers/editions_controller_test.rb
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/editions_controller.rb test/controllers/editions_controller_test.rb
git commit -m "feat(routing): make edition show_current the site root"
```

---

## Task 4: Masthead partial — five-row structure

**Files:**
- Modify: `app/views/editions/_masthead.html.erb`
- Modify: `test/controllers/editions_controller_test.rb`

`editions(:one)` belongs to `newspapers(:one)` — no new fields, used for null-safety tests.
`editions(:two)` belongs to `newspapers(:two)` — all new fields populated, used for full-render tests.

- [ ] **Step 1: Write the failing tests**

Add to `test/controllers/editions_controller_test.rb`:

```ruby
test "masthead renders edition_type and price when present" do
  get newspaper_edition_url(editions(:two).newspaper, editions(:two))
  assert_select ".masthead-edition-type", text: "Extra Edition"
  assert_select ".masthead-price", text: "Two Pennies"
end

test "masthead omits meta row when edition_type and price are nil" do
  get newspaper_edition_url(editions(:one).newspaper, editions(:one))
  assert_select ".masthead-meta", count: 0
end

test "masthead renders tagline when present" do
  get newspaper_edition_url(editions(:two).newspaper, editions(:two))
  assert_select ".masthead-tagline"
end

test "masthead omits tagline when nil" do
  get newspaper_edition_url(editions(:one).newspaper, editions(:one))
  assert_select ".masthead-tagline", count: 0
end

test "masthead info row includes city when present" do
  get newspaper_edition_url(editions(:two).newspaper, editions(:two))
  assert_select ".masthead-info__date" do |nodes|
    assert_match(/Flint/, nodes.first.text)
  end
end

test "masthead info row omits city separator when city is nil" do
  get newspaper_edition_url(editions(:one).newspaper, editions(:one))
  assert_select ".masthead-info__date" do |nodes|
    assert_no_match(/ — /, nodes.first.text)
  end
end

test "masthead info row omits print_location when nil" do
  get newspaper_edition_url(editions(:one).newspaper, editions(:one))
  assert_select ".masthead-info__location", text: ""
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/controllers/editions_controller_test.rb
```

Expected: FAIL — classes like `.masthead-edition-type` don't exist yet.

- [ ] **Step 3: Rewrite `app/views/editions/_masthead.html.erb`**

```erb
<%# locals: (edition:) %>
<header class="masthead">

  <% if edition.edition_type.present? || edition.price.present? %>
    <div class="masthead-meta">
      <% if edition.edition_type.present? %>
        <span class="masthead-edition-type"><%= edition.edition_type %></span>
      <% end %>
      <% if edition.price.present? %>
        <span class="masthead-price"><%= edition.price %></span>
      <% end %>
    </div>
  <% end %>

  <h1 class="masthead-title">
    <% before, separator, after = edition.newspaper.name.partition(" of ") %>
    <%= before %><% if separator.present? %><em>of</em><% end %><%= after %>
  </h1>

  <% if edition.newspaper.tagline.present? %>
    <p class="masthead-tagline">✦ <%= edition.newspaper.tagline %> ✦</p>
  <% end %>

  <div class="masthead-info">
    <span class="masthead-info__vol">Vol. <%= edition.volume %> · No. <%= edition.issue_number %></span>
    <span class="masthead-info__date">
      <% if edition.city.present? %>
        <%= edition.city %> —
      <% end %>
      <%= edition.label %>
    </span>
    <span class="masthead-info__location"><%= edition.newspaper.print_location %></span>
  </div>

  <% if edition.attention_bar.present? %>
    <p class="attention-bar"><%= edition.attention_bar %></p>
  <% end %>

</header>
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
bin/rails test test/controllers/editions_controller_test.rb
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add app/views/editions/_masthead.html.erb test/controllers/editions_controller_test.rb
git commit -m "feat(views): restructure masthead with five-row layout"
```

---

## Task 5: Masthead CSS — new layout + attention bar restyle

**Files:**
- Modify: `app/assets/stylesheets/components/masthead.css`
- Modify: `app/assets/stylesheets/base/typography.css`

- [ ] **Step 1: Replace `app/assets/stylesheets/components/masthead.css`**

```css
/*
 * Masthead component — five-row newspaper header.
 * Attention bar styles live here (not typography.css) because they are
 * layout-dependent (full-width dark band, part of the masthead block).
 */

.masthead {
  padding: 1rem 1rem 0;
  text-align: center;
  border-bottom: calc(var(--rule-width) * 3) double var(--color-rule);
  margin-bottom: 1.5rem;
}

/* Row 1 — edition type + price */
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

.masthead-edition-type {
  font-variant: small-caps;
}

.masthead-price {
  background: var(--color-ink);
  color: var(--color-paper);
  padding: 0.1rem 0.5rem;
}

/* Row 2 — nameplate */
.masthead-title em {
  font-style: italic;
}

/* Row 3 — tagline */
.masthead-tagline {
  font-family: var(--font-body);
  font-style: italic;
  font-size: 0.875rem;
  color: var(--color-ink-muted);
  margin: 0.25rem 0 0.5rem;
  letter-spacing: 0.03em;
}

/* Row 4 — three-column info row */
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

.masthead-info__vol  { text-align: left; }
.masthead-info__date { text-align: center; }
.masthead-info__location { text-align: right; }

/* Row 5 — attention bar */
.attention-bar {
  font-family: var(--font-headline);
  font-weight: bold;
  text-align: center;
  padding: 0.4rem 1rem;
  margin: 0 -1rem;
  background: var(--color-ink);
  color: var(--color-paper);
  letter-spacing: 0.06em;
  font-size: 0.875rem;
}
```

- [ ] **Step 2: Remove attention bar styles from `app/assets/stylesheets/base/typography.css`**

Delete these lines from `typography.css`:

```css
.attention-bar {
  font-family: var(--font-headline);
  color: var(--color-accent);
  font-weight: bold;
  text-align: center;
  padding: 0.5rem 1rem;
  border-top: var(--rule-width) solid var(--color-rule);
  border-bottom: var(--rule-width) solid var(--color-rule);
}
```

- [ ] **Step 3: Run full test suite**

```bash
bin/rails test
```

Expected: all pass (CSS changes don't affect HTML structure tests).

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/components/masthead.css app/assets/stylesheets/base/typography.css
git commit -m "feat(css): restyle masthead with five-row layout and dark attention bar"
```

---

## Task 6: Broadsheet theme CSS

**Files:**
- Create: `app/assets/stylesheets/themes/broadsheet.css`
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Create `app/assets/stylesheets/themes/broadsheet.css`**

```css
/*
 * Theme: Broadsheet
 * Character: Dignified grey. Authoritative. Stately.
 *
 * Applied via [data-theme="broadsheet"] on <body>, overriding the
 * per-newspaper [data-newspaper="..."] tokens. Layout tokens are
 * intentionally not overridden — only palette and type change.
 */

@import url('https://fonts.googleapis.com/css2?family=UnifrakturMaguntia&family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Lora:ital,wght@0,400;0,700;1,400&display=swap');

[data-theme="broadsheet"] {
  --color-paper:      #f0ede6;
  --color-ink:        #1a1a1a;
  --color-ink-muted:  #555555;
  --color-rule:       #1a1a1a;
  --color-accent:     #1a1a1a;
  --color-background: #c8c4bc;

  --font-masthead: "UnifrakturMaguntia", serif;
  --font-headline: "Playfair Display", serif;
  --font-body:     "Lora", Georgia, serif;
}
```

- [ ] **Step 2: Add the import to `app/assets/stylesheets/application.css`**

Add `@import "themes/broadsheet.css";` after the pryce_of_progress import:

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
@import "themes/broadsheet.css";
```

- [ ] **Step 3: Run full test suite**

```bash
bin/rails test
```

Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/themes/broadsheet.css app/assets/stylesheets/application.css
git commit -m "feat(css): add Broadsheet theme with grey palette and Playfair/Lora/UnifrakturMaguntia fonts"
```

---

## Task 7: ThemesController + route

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/themes_controller.rb`
- Create: `test/controllers/themes_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/controllers/themes_controller_test.rb`:

```ruby
require "test_helper"

class ThemesControllerTest < ActionDispatch::IntegrationTest
  test "stores broadsheet in session" do
    patch theme_url, params: { theme: "broadsheet" }
    assert_equal "broadsheet", session[:theme]
  end

  test "clears session for empty string" do
    patch theme_url, params: { theme: "" }
    assert_nil session[:theme]
  end

  test "clears session for unrecognised theme" do
    patch theme_url, params: { theme: "hacker" }
    assert_nil session[:theme]
  end

  test "clears existing session value when default requested" do
    patch theme_url, params: { theme: "broadsheet" }
    patch theme_url, params: { theme: "" }
    assert_nil session[:theme]
  end

  test "redirects back to root" do
    patch theme_url, params: { theme: "broadsheet" }
    assert_redirected_to root_url
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/controllers/themes_controller_test.rb
```

Expected: FAIL — `theme_url` routing error, no route matches.

- [ ] **Step 3: Add route to `config/routes.rb`**

Add `resource :theme, only: [:update]` before the root line:

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

  resource :theme, only: [:update]

  root "editions#show_current"
end
```

- [ ] **Step 4: Create `app/controllers/themes_controller.rb`**

```ruby
class ThemesController < ApplicationController
  VALID_THEMES = %w[broadsheet].freeze

  def update
    if VALID_THEMES.include?(params[:theme])
      session[:theme] = params[:theme]
    else
      session.delete(:theme)
    end

    redirect_back fallback_location: root_path
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
bin/rails test test/controllers/themes_controller_test.rb
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add config/routes.rb app/controllers/themes_controller.rb test/controllers/themes_controller_test.rb
git commit -m "feat(themes): add ThemesController to persist theme in session"
```

---

## Task 8: SelectMenuComponent

**Files:**
- Create: `app/components/select_menu_component.rb`
- Create: `app/components/select_menu_component.html.erb`
- Create: `test/components/select_menu_component_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/components/select_menu_component_test.rb`:

```ruby
require "test_helper"

class SelectMenuComponentTest < ViewComponent::TestCase
  def theme_options
    [["Yellow Sheets", ""], ["Broadsheet", "broadsheet"]]
  end

  test "renders a select with the given name" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: "", name: "theme"))
    assert_selector "select[name='theme']"
  end

  test "renders all options" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: "", name: "theme"))
    assert_selector "option", count: 2
    assert_selector "option[value='']",            text: "Yellow Sheets"
    assert_selector "option[value='broadsheet']",  text: "Broadsheet"
  end

  test "marks the matching option as selected" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: "broadsheet", name: "theme"))
    assert_selector "option[value='broadsheet'][selected]"
    assert_no_selector "option[value=''][selected]"
  end

  test "selects empty-value option when selected is nil" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: nil, name: "theme"))
    assert_selector "option[value=''][selected]"
  end

  test "passes through html options" do
    render_inline(SelectMenuComponent.new(options: theme_options, selected: nil, name: "theme", class: "my-select"))
    assert_selector "select.my-select"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/components/select_menu_component_test.rb
```

Expected: FAIL — `SelectMenuComponent` does not exist.

- [ ] **Step 3: Create `app/components/select_menu_component.rb`**

```ruby
class SelectMenuComponent < ViewComponent::Base
  def initialize(options:, selected:, name:, **html_options)
    @options      = options
    @selected     = selected.to_s
    @name         = name
    @html_options = html_options
  end
end
```

- [ ] **Step 4: Create `app/components/select_menu_component.html.erb`**

```erb
<%= select_tag @name, options_for_select(@options, @selected), **@html_options %>
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
bin/rails test test/components/select_menu_component_test.rb
```

Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/components/select_menu_component.rb app/components/select_menu_component.html.erb test/components/select_menu_component_test.rb
git commit -m "feat(components): add SelectMenuComponent"
```

---

## Task 9: NavbarComponent + CSS

**Files:**
- Create: `app/components/navbar_component.rb`
- Create: `app/components/navbar_component.html.erb`
- Create: `app/assets/stylesheets/components/navbar.css`
- Create: `test/components/navbar_component_test.rb`

- [ ] **Step 1: Write the failing tests**

Create `test/components/navbar_component_test.rb`:

```ruby
require "test_helper"

class NavbarComponentTest < ViewComponent::TestCase
  test "renders site name" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector ".site-navbar__name", text: "Zeitgeist Press"
  end

  test "renders a form posting to /theme" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector "form[action='/theme']"
  end

  test "renders a theme select inside the form" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector "form select[name='theme']"
  end

  test "selects Yellow Sheets when theme is nil" do
    render_inline(NavbarComponent.new(current_theme: nil))
    assert_selector "option[value=''][selected]"
    assert_no_selector "option[value='broadsheet'][selected]"
  end

  test "selects Broadsheet when theme is broadsheet" do
    render_inline(NavbarComponent.new(current_theme: "broadsheet"))
    assert_selector "option[value='broadsheet'][selected]"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
bin/rails test test/components/navbar_component_test.rb
```

Expected: FAIL — `NavbarComponent` does not exist.

- [ ] **Step 3: Create `app/components/navbar_component.rb`**

```ruby
class NavbarComponent < ViewComponent::Base
  def initialize(current_theme:)
    @current_theme = current_theme
  end

  def theme_options
    [["Yellow Sheets", ""], ["Broadsheet", "broadsheet"]]
  end
end
```

- [ ] **Step 4: Create `app/components/navbar_component.html.erb`**

```erb
<nav class="site-navbar">
  <span class="site-navbar__name">Zeitgeist Press</span>
  <%= form_with url: theme_path, method: :patch,
        data: { controller: "theme-switcher", action: "change->theme-switcher#change" } do %>
    <%= render SelectMenuComponent.new(
          options: theme_options,
          selected: @current_theme,
          name: "theme"
        ) %>
  <% end %>
</nav>
```

- [ ] **Step 5: Create `app/assets/stylesheets/components/navbar.css`**

```css
.site-navbar {
  background: #1a1a1a;
  color: #e8e4d8;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.35rem 1.5rem;
  font-size: 0.75rem;
  font-family: var(--font-body, serif);
}

.site-navbar__name {
  text-transform: uppercase;
  letter-spacing: 0.1em;
  opacity: 0.5;
}

.site-navbar select {
  background: transparent;
  color: #e8e4d8;
  border: 1px solid rgba(232, 228, 216, 0.4);
  padding: 0.15rem 0.4rem;
  font-size: 0.7rem;
  font-family: inherit;
  cursor: pointer;
}

.site-navbar select option {
  background: #1a1a1a;
}
```

- [ ] **Step 6: Add navbar.css import to `app/assets/stylesheets/application.css`**

```css
@import "base/tokens.css";
@import "base/typography.css";
@import "themes/pryce_of_progress.css";
@import "themes/broadsheet.css";
@import "components/navbar.css";
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
bin/rails test test/components/navbar_component_test.rb
```

Expected: all pass.

- [ ] **Step 8: Commit**

```bash
git add app/components/navbar_component.rb app/components/navbar_component.html.erb \
        app/assets/stylesheets/components/navbar.css \
        app/assets/stylesheets/application.css \
        test/components/navbar_component_test.rb
git commit -m "feat(components): add NavbarComponent with theme switcher"
```

---

## Task 10: FooterComponent + CSS

**Files:**
- Create: `app/components/footer_component.rb`
- Create: `app/components/footer_component.html.erb`
- Create: `app/assets/stylesheets/components/footer.css`
- Create: `test/components/footer_component_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/components/footer_component_test.rb`:

```ruby
require "test_helper"

class FooterComponentTest < ViewComponent::TestCase
  test "renders a footer element with the site-footer class" do
    render_inline(FooterComponent.new)
    assert_selector "footer.site-footer"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
bin/rails test test/components/footer_component_test.rb
```

Expected: FAIL — `FooterComponent` does not exist.

- [ ] **Step 3: Create `app/components/footer_component.rb`**

```ruby
class FooterComponent < ViewComponent::Base
end
```

- [ ] **Step 4: Create `app/components/footer_component.html.erb`**

```erb
<footer class="site-footer"></footer>
```

- [ ] **Step 5: Create `app/assets/stylesheets/components/footer.css`**

```css
.site-footer {
  border-top: var(--rule-width) solid var(--color-rule);
  margin-top: 2rem;
}
```

- [ ] **Step 6: Add footer.css import to `app/assets/stylesheets/application.css`**

```css
@import "base/tokens.css";
@import "base/typography.css";
@import "themes/pryce_of_progress.css";
@import "themes/broadsheet.css";
@import "components/navbar.css";
@import "components/footer.css";
```

- [ ] **Step 7: Run test to verify it passes**

```bash
bin/rails test test/components/footer_component_test.rb
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add app/components/footer_component.rb app/components/footer_component.html.erb \
        app/assets/stylesheets/components/footer.css \
        app/assets/stylesheets/application.css \
        test/components/footer_component_test.rb
git commit -m "feat(components): add FooterComponent"
```

---

## Task 11: Stimulus theme-switcher controller

**Files:**
- Create: `app/javascript/controllers/theme_switcher_controller.js`

- [ ] **Step 1: Create `app/javascript/controllers/theme_switcher_controller.js`**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  change() {
    this.element.requestSubmit()
  }
}
```

The Stimulus auto-loader in `app/javascript/controllers/index.js` discovers controllers by filename convention — `theme_switcher_controller.js` maps to `theme-switcher`. No manual registration needed.

- [ ] **Step 2: Run full test suite**

```bash
bin/rails test
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add app/javascript/controllers/theme_switcher_controller.js
git commit -m "feat(js): add theme-switcher Stimulus controller"
```

---

## Task 12: Wire application layout

**Files:**
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 1: Update `app/views/layouts/application.html.erb`**

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Zeitgeist Press" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="application-name" content="Zeitgeist Press">
    <meta name="mobile-web-app-capable" content="yes">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= yield :head %>

    <link rel="icon" href="/icon.png" type="image/png">
    <link rel="icon" href="/icon.svg" type="image/svg+xml">
    <link rel="apple-touch-icon" href="/icon.png">

    <%= stylesheet_link_tag :app, "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body data-newspaper="<%= @edition&.newspaper&.slug %>"
        data-theme="<%= session[:theme] %>">
    <%= render NavbarComponent.new(current_theme: session[:theme]) %>
    <%= yield %>
    <%= render FooterComponent.new %>
  </body>
</html>
```

- [ ] **Step 2: Run full test suite**

```bash
bin/rails test
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add app/views/layouts/application.html.erb
git commit -m "feat(layout): wire NavbarComponent, FooterComponent, and data-theme into application layout"
```

---

## Task 13: README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace `README.md`**

```markdown
# Zeitgeist Press

A newspaper front page archive for a gaslight-era tabletop RPG campaign — and a demonstration of modern Rails patterns.

## What it is

Zeitgeist Press publishes fictional newspaper editions from the world of the [Zeitgeist TTRPG](https://www.rpgpublisher.com/). Each edition displays a front page laid out in a CSS grid, with stories slotted by type (major headline, secondary, tertiary, advertisement). Stories that overflow their cell reveal a "Continued on page #" link; clicking it opens the full story in an overlay styled as a newspaper cutout.

The project is also a deliberate showcase of the following technologies working together:

- **Hotwire Turbo Frames** — the story overlay loads lazily inside a `<turbo-frame>` with no custom fetch code
- **Hotwire Turbo Drive** — all navigation is SPA-like without a JavaScript framework
- **Stimulus** — small, focused controllers for overflow detection and the theme switcher
- **ViewComponent** — typed, testable Ruby components for the story card, navbar, footer, and select menu
- **CSS custom property design tokens** — a two-layer token system (`base/tokens.css` + per-newspaper theme files) powers multiple visual themes from a single stylesheet
- **Rails 8.1** — Solid Queue, Solid Cache, Solid Cable, Propshaft, importmap — the full zero-Node stack

## Running locally

```bash
bundle install
bin/rails db:setup   # creates database, runs migrations, seeds Pryce of Progress
bin/dev              # starts Puma + asset watcher
```

Visit `http://localhost:3000`.

## Tech stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.3.5 |
| Framework | Rails 8.1 |
| Database | SQLite (via Solid Queue / Cache / Cable) |
| Asset pipeline | Propshaft + importmap (no Node.js) |
| Frontend interactivity | Hotwire Turbo + Stimulus + Alpine.js |
| Component library | ViewComponent |
| Deployment | Kamal 2 |
| Testing | Minitest + Capybara |
```

- [ ] **Step 2: Run full test suite**

```bash
bin/rails test
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: add README describing project goals and tech stack"
```
