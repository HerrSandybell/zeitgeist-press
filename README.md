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
