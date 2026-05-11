# MVP Polish Design

> **For agentic workers:** After reviewing this spec, use `superpowers:writing-plans` to create the implementation plan.

**Goal:** Ship a presentable, production-ready front page — richer masthead, a Broadsheet visual theme, a minimal navbar/footer with a reusable theme-switcher component, and the edition view as the site root.

**Scope:** Four features ship together as one milestone. AWS deployment is a separate milestone.

---

## 1. Data Model Changes

### Newspaper (new fields)

| Field | Type | Required | Notes |
|---|---|---|---|
| `tagline` | string | no | e.g. "What the Tribune Will Not Tell You — Twice a Week, Sometimes Thrice" |
| `print_location` | string | no | e.g. "Printed in Bosum Strand" |

### Edition (new fields)

| Field | Type | Required | Notes |
|---|---|---|---|
| `edition_type` | string | no | e.g. "Extra Edition" |
| `price` | string | no | e.g. "Two Pennies" |
| `city` | string | no | e.g. "Flint" |

All five fields are nullable. Views must never render a dangling label or separator for a nil field — see Section 2 for fallback rules.

### Migrations

Two migrations: one for `newspapers`, one for `editions`. Both `add_column` with no default.

### Seed data

Update the Pryce of Progress seed record with all five values:
- `tagline`: "What the Tribune Will Not Tell You — Twice a Week, Sometimes Thrice"
- `print_location`: "Printed in Bosum Strand"
- `edition_type`: "Extra Edition"
- `price`: "Two Pennies"
- `city`: "Flint"

---

## 2. Masthead Layout

### File

`app/views/editions/_masthead.html.erb` — restructured into five conditional rows.
`app/assets/stylesheets/components/masthead.css` — extended for new layout.
`app/assets/stylesheets/base/typography.css` — attention bar styles move to `masthead.css`.

### Row structure

**Row 1 — Edition meta (top bar)**
Rendered only if `edition_type` or `price` is present.
- Left: `edition_type` in small caps. Omitted if nil.
- Right: `price` in an ink-coloured box. Omitted if nil.

**Row 2 — Nameplate**
Always rendered. `newspaper.name` unchanged in markup. CSS gives any `<em>` inside the title italic treatment (the "of" in "Pryce *of* Progress" is marked up as `<em>` in the nameplate).

**Row 3 — Tagline**
Rendered only if `newspaper.tagline` is present.
Format: `✦ <%= newspaper.tagline %> ✦`

**Row 4 — Info row (three-column grid)**
Always rendered (vol/issue/date always exist).
- Left cell: `Vol. <%= edition.volume %> · No. <%= edition.issue_number %>`
- Centre cell: `<%= edition.city %> — <%= edition.label %>` if `city` present, otherwise just `<%= edition.label %>`
- Right cell: `<%= edition.newspaper.print_location %>` — omitted (empty cell) if nil

**Row 5 — Attention bar**
Unchanged in logic (existing `edition.attention_bar`). Restyled: dark background (`--color-ink`), light text (`--color-paper`), full-width.

### Null safety summary

| Field | Nil behaviour |
|---|---|
| `edition_type` | Row 1 left omitted |
| `price` | Row 1 right omitted; Row 1 hidden if both nil |
| `tagline` | Row 3 omitted entirely |
| `city` | Centre cell shows date only, no leading dash |
| `print_location` | Right cell empty |

---

## 3. Root Route

### Change

`config/routes.rb`: replace `root "newspapers#index"` with `root "editions#show_current"`.

### New action

`EditionsController#show_current` finds the first published edition ordered by `id` and renders it using the existing `show` template and instance variables (`@edition`, `@stories`). Raises `ActiveRecord::RecordNotFound` if none exists (standard 404). No redirect — URL stays `/`.

---

## 4. Broadsheet Theme

### File

`app/assets/stylesheets/themes/broadsheet.css`

### Selector

`[data-theme="broadsheet"]` on `<body>` — overrides the `[data-newspaper="..."]` tokens set by the newspaper theme.

### Tokens

```css
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

Grid layout tokens (`--grid-row-unit`, `--grid-columns`, column/row spans) are not overridden — layout stays identical between themes.

### Google Fonts import

```css
@import url('https://fonts.googleapis.com/css2?family=UnifrakturMaguntia&family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Lora:ital,wght@0,400;0,700;1,400&display=swap');
```

### Application layout

`application.html.erb` body tag:

```erb
<body data-newspaper="<%= @edition&.newspaper&.slug %>"
      data-theme="<%= session[:theme] %>">
```

When `session[:theme]` is nil the attribute is present but empty — this is harmless; no `[data-theme="broadsheet"]` rules fire.

---

## 5. Theme Switcher

### Route

```ruby
resource :theme, only: [:update]   # PATCH /theme
```

### Controller

`app/controllers/themes_controller.rb` — `update` action. Validates `params[:theme]` against allowlist `%w[broadsheet]`. Values in the allowlist are stored in `session[:theme]`. Any other value (nil, empty string, or unrecognised) deletes `session[:theme]`, reverting to the default Yellow Sheets. Redirects back to `request.referer || root_path`.

### Stimulus controller

`app/javascript/controllers/theme_switcher_controller.js` — listens to `change` on the `<select>` and calls `this.element.closest("form").requestSubmit()`. One action, no targets needed.

---

## 6. ViewComponents

### SelectMenuComponent

**Files:** `app/components/select_menu_component.rb`, `app/components/select_menu_component.html.erb`

Renders a `<select>` element only — no form wrapper. Caller owns the form.

**Arguments:**
- `options:` — array of `[label, value]` pairs
- `selected:` — currently selected value (string or nil)
- `name:` — the `name` attribute for the select
- `**html_options` — passed through to the `<select>` tag (e.g. `data:`, `class:`)

### NavbarComponent

**Files:** `app/components/navbar_component.rb`, `app/components/navbar_component.html.erb`

Renders the minimal dark utility bar.

**Arguments:** `current_theme:` (string or nil)

**Structure:**
```
<nav class="site-navbar">
  <span class="site-navbar__name">Zeitgeist Press</span>
  <form action="/theme" method="post" data-controller="theme-switcher">
    [CSRF token]
    [PATCH override]
    [SelectMenuComponent — themes list, current_theme selected]
  </form>
</nav>
```

Theme options passed to `SelectMenuComponent`: `[["Yellow Sheets", ""], ["Broadsheet", "broadsheet"]]`

### FooterComponent

**Files:** `app/components/footer_component.rb`, `app/components/footer_component.html.erb`

Renders a single rule line. No arguments.

```html
<footer class="site-footer"></footer>
```

```css
.site-footer {
  border-top: var(--rule-width) solid var(--color-rule);
  margin-top: 2rem;
}
```

### Application layout

```erb
<body ...>
  <%= render NavbarComponent.new(current_theme: session[:theme]) %>
  <%= yield %>
  <%= render FooterComponent.new %>
</body>
```

---

## 7. README

`README.md` at project root. Content:

- **What it is** — a newspaper front page archive for a gaslight-era TTRPG campaign, built as a demonstration of Rails 8 / Hotwire / ViewComponent / CSS design system patterns.
- **Tech highlights** — Hotwire Turbo Frames (story overlay), Stimulus controllers (overflow detection, theme switcher), ViewComponent, CSS custom property token system with per-newspaper themes, Rails 8.1 / SQLite / Kamal 2.
- **Running locally** — `bundle install`, `bin/rails db:setup`, `bin/dev`.
- No contribution guide. No license section.

---

## File Map

| Action | File |
|---|---|
| Create | `db/migrate/TIMESTAMP_add_fields_to_newspapers.rb` |
| Create | `db/migrate/TIMESTAMP_add_fields_to_editions.rb` |
| Modify | `db/seeds.rb` |
| Modify | `app/models/newspaper.rb` (no-op — nullable, no validations needed) |
| Modify | `app/models/edition.rb` (no-op — nullable, no validations needed) |
| Modify | `app/views/editions/_masthead.html.erb` |
| Modify | `app/assets/stylesheets/components/masthead.css` |
| Modify | `app/assets/stylesheets/base/typography.css` (remove attention bar styles) |
| Modify | `config/routes.rb` |
| Modify | `app/controllers/editions_controller.rb` |
| Create | `app/assets/stylesheets/themes/broadsheet.css` |
| Modify | `app/views/layouts/application.html.erb` |
| Create | `app/controllers/themes_controller.rb` |
| Create | `app/javascript/controllers/theme_switcher_controller.js` |
| Create | `app/components/select_menu_component.rb` |
| Create | `app/components/select_menu_component.html.erb` |
| Create | `app/components/navbar_component.rb` |
| Create | `app/components/navbar_component.html.erb` |
| Create | `app/components/footer_component.rb` |
| Create | `app/components/footer_component.html.erb` |
| Modify | `README.md` |

## Testing

- Unit tests for `SelectMenuComponent`, `NavbarComponent`, `FooterComponent` — cover rendered HTML for present/nil arguments.
- Unit test for `ThemesController#update` — valid theme stored in session; invalid theme rejected; nil clears session.
- Unit test for `EditionsController#show_current` — renders published edition; 404 when none published.
- Masthead partial tests — each nullable field present vs nil produces correct HTML (no dangling separators).
- No system tests required for this milestone (visual changes, theme switching).
