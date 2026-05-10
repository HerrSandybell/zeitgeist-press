# Zeitgeist Press

A newspaper front page archive for a gaslight-era tabletop RPG campaign.

## Concept

Each newspaper edition contains several stories slotted into a fixed front page layout. Stories that overflow their allotted space show a "Continued on page #" link, which opens an overlay displaying the full story as a newspaper cutout.

## Tech Stack

- **Ruby on Rails** — backend, routing, data
- **Hotwire Turbo Streams** — dynamic page updates without full reloads
- **Alpine.js** — lightweight interactivity (overlays, toggles)
- **Semantic Tokens** — design system foundation
- **SQLite** — database (development)

## Data Model

### Newspaper
| Field | Type | Notes |
|-------|------|-------|
| name | string | |

### Edition
| Field | Type | Notes |
|-------|------|-------|
| newspaper_id | foreign key | |
| year | integer | |
| season | enum | spring, summer, autumn, winter |
| day | integer | 1–90 |
| volume | integer | |
| issue_number | integer | |
| attention_bar | string | optional — the bold banner across the top |
| published | boolean | default: false |

### Story
| Field | Type | Notes |
|-------|------|-------|
| edition_id | foreign key | optional — stories can exist without an edition |
| story_type | enum | major, secondary, tertiary, advertisement |
| position | integer | ordering within the edition |
| headline | string | |
| body | text | |
| supertitle | string | optional — e.g. "A Dispatch from the Cultural Front" |
| subtitle | string | optional — e.g. "The Guild Knew They Were Coming..." |
| author | string | optional |
| quote | text | optional |
| quote_origin | string | optional |
| summary_ticker | string | optional — e.g. "Officers Killed — Twice as Many Wounded —..." |

## Milestones

### M1 — Core (current)
- Data model: Edition, Story (with story types)
- Front page layout with stories slotted by type
- "Continued on page #" overlay for overflowing stories
- Seed data from existing editions

### M2 — Future
- In-app AI story generation via Claude API
- Chat window with tool-use to save approved editions/stories to the database
- Approval/edit flow before persisting

## Out of Scope (for now)

- Multiple newspapers/publications
- User accounts or authentication
- Image handling

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Zeitgeist Press**

A Rails 8.1 web app for publishing and browsing historical newspaper editions. Built around a multi-publication model: a Newspaper publishes Editions, each Edition contains typed Stories (major headlines, secondary pieces, tertiary items, and advertisements). The seed data is set in a fictional steampunk world (Zeitgeist TTRPG), but the platform is a general newspaper publisher.

**Core Value:** Readers can browse published newspaper editions and read the stories within them — the publishing model is solid, the reading experience does not exist yet.

### Constraints

- **Tech stack**: Rails 8.1 / Ruby 3.3.5 / SQLite — do not introduce PostgreSQL or Node.js build pipeline
- **SSL**: Kamal 2 deploys behind a reverse proxy — `assume_ssl` is the correct setting, not raw `force_ssl` alone
- **Testing**: Minitest + YAML fixtures only (no RSpec, no FactoryBot)
- **JS**: Importmap + Stimulus — no bundler
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Runtime & Language
- **Ruby 3.3.5** — application language (pinned in `.ruby-version`)
- **Bundler 2.5.16** — gem dependency manager (lockfile present: `Gemfile.lock`)
## Core Frameworks
- **Ruby on Rails 8.1.3** — full-stack web framework; all Rails components in use (ActionCable, ActionMailbox, ActionMailer, ActionText, ActiveJob, ActiveStorage, ActiveRecord)
- **Hotwire Turbo 2.0.23** (`turbo-rails`) — SPA-like page updates via Turbo Streams/Frames, no full reloads
- **Hotwire Stimulus 1.3.4** (`stimulus-rails`) — modest JS framework for behavior attached to HTML
- **Alpine.js 3.15.12** — lightweight inline interactivity (overlays, toggles); loaded via importmap
## Key Dependencies
- `puma` 8.0.1 — multi-threaded application server; default 3 threads (`RAILS_MAX_THREADS`)
- `thruster` 0.1.20 — HTTP caching/compression proxy in front of Puma in production
- `propshaft` 1.3.2 — asset pipeline (replaces Sprockets)
- `importmap-rails` 2.2.3 — ESM importmaps for JavaScript (no bundler/Node required)
- `jbuilder` 2.14.1 — JSON view templates
- `sqlite3` 2.9.4 — ActiveRecord adapter; four SQLite databases in production (primary, cache, queue, cable)
- `solid_queue` 1.4.0 — DB-backed job queue (SQLite); runs inside Puma process in single-server mode via `plugin :solid_queue`
- `solid_cable` 3.0.12 — DB-backed Action Cable adapter (SQLite)
- `solid_cache` 1.0.10 — DB-backed Rails cache (SQLite)
- `image_processing` 1.14.0 — Active Storage variants
- `ruby-vips` 2.3.0 / `mini_magick` 5.3.1 — image processing backends; `libvips` installed in Docker image
- `kamal` 2.11.0 — Docker-based deploy tool; config at `config/deploy.yml`
- `brakeman` 8.0.4 — Rails security scanner (run in CI)
- `bundler-audit` 0.9.3 — gem vulnerability scanner (run in CI)
- `minitest` 6.0.6 — test runner (built into Rails)
- `capybara` 3.40.0 — system/integration test DSL
- `selenium-webdriver` 4.43.0 — browser automation for system tests
- `web-console` 4.3.0 — in-browser Rails console on error pages
- `debug` 1.11.1 — Ruby debugger
## Build & Tooling
- **No Node.js / npm** — importmap-rails eliminates the need for a JavaScript build pipeline
- **Rake** 13.4.2 — task runner (`bin/rake`)
- **Bootsnap** 1.24.3 — boot time cache; precompiled in Docker build for both gems and app code
- **RuboCop** 1.86.1 with `rubocop-rails-omakase` 1.1.0 — linting/style enforcement; config at `.rubocop.yml`
- `bin/dev` — local development launcher
- `bin/ci` — CI helper script
- `bin/brakeman`, `bin/bundler-audit`, `bin/rubocop` — binstubs for security/lint tools
## Infrastructure
- **Docker** — production container; multi-stage build (build + runtime stages); base image `ruby:3.3.5-slim`
- **Kamal 2** — deployment orchestration; config at `config/deploy.yml`
- **GitHub Actions** — CI pipeline at `.github/workflows/ci.yml`
- **Dependabot** — weekly updates for Bundler and GitHub Actions (`.github/dependabot.yml`)
## Notable Config
- `config/database.yml` — four SQLite databases in production: `production.sqlite3`, `production_cache.sqlite3`, `production_queue.sqlite3`, `production_cable.sqlite3`
- `config/puma.rb` — 3 threads default; `SOLID_QUEUE_IN_PUMA=true` runs Solid Queue inside Puma
- `config/queue.yml` — Solid Queue: 1 dispatcher (500 batch), 3 worker threads, `JOB_CONCURRENCY` env var
- `config/cable.yml` — Solid Cable in production; async adapter in development
- `config/cache.yml` — Solid Cache
- `config/recurring.yml` — one recurring job in production: `SolidQueue::Job.clear_finished_in_batches` every hour at minute 12
- `config/storage.yml` — Active Storage on local disk; S3/GCS configs commented out
- `config/importmap.rb` — pins Turbo, Stimulus, Alpine.js 3.15.12
- `config/deploy.yml` — Kamal deploy config; `RAILS_MASTER_KEY` injected as secret; `SOLID_QUEUE_IN_PUMA=true` set as clear env var
- `config/credentials.yml.enc` — encrypted credentials (decrypted with `config/master.key`)
- `.dockerignore` — present
- `.gitattributes` — present
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming
- Standard Rails conventions: snake_case for files, methods, DB columns; CamelCase for classes
- Enum columns use integer-backed values defined inline in models
- No custom naming deviations detected
## Code Style & Linting
- RuboCop with `rubocop-rails-omakase` ruleset (Basecamp's opinionated defaults)
- No custom overrides — `.rubocop.yml` inherits the gem config as-is
## Common Patterns
- Thin models with inline validations and enum definitions
- Idempotent seeds via `find_or_create_by!`
- No service objects, decorators, or presenters observed — standard Rails MVC only
- No ActiveRecord concerns or mixins detected
## Error Handling
- No custom error handling beyond Rails defaults
- No custom exception classes or rescue middleware
## Logging
- Default Rails logger — no custom log formatting or structured logging
## Documentation Style
- Minimal inline comments
- No YARD or RDoc-style documentation observed
## Git Conventions
- Short imperative commit messages (Rails scaffold style)
- Single `main` branch — no feature branch convention observed
- No PR templates or commit hooks detected
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern & Style
```
```
## Core Components
| Component | Responsibility | File |
|-----------|----------------|------|
| `Newspaper` model | Top-level publication entity; owns editions | `app/models/newspaper.rb` |
| `Edition` model | A single published issue (volume, issue, season, day); owns stories | `app/models/edition.rb` |
| `Story` model | An individual article or advertisement within an edition | `app/models/story.rb` |
| `ApplicationController` | Base controller; enforces modern browser requirement | `app/controllers/application_controller.rb` |
| Hotwire Turbo | In-place page updates without full reloads | gem `turbo-rails` |
| Alpine.js | Client-side interactivity (overlays, toggles) | pinned via importmap |
| Solid Queue | Database-backed background job processing | gem `solid_queue`, DB: `production_queue.sqlite3` |
| Solid Cache | Database-backed HTTP/fragment caching | gem `solid_cache`, DB: `production_cache.sqlite3` |
| Solid Cable | Database-backed Action Cable adapter | gem `solid_cable`, DB: `production_cable.sqlite3` |
## Data Flow
### Page Request
### Story Overflow (planned)
## Auth Model
## Background Processing
- Config: `config/queue.yml`
- Workers: 3 threads, 1 process by default (controlled via `JOB_CONCURRENCY` env var)
- Dispatchers: 1, polling interval 1s, batch size 500
- Recurring jobs: `config/recurring.yml` — one production job clears finished Solid Queue job records hourly
## Caching
- Config: `config/cache.yml`
- Max size: 256 MB
- Namespaced by Rails environment
- Fragment caching enabled in production (`config.action_controller.perform_caching = true`)
- Static assets cached with far-future expiry headers (1 year) via Thruster and Propshaft digest stamping
- Development/test: in-process memory cache (Solid Cache only activates in production)
## API Design
- `GET /up` — Rails health check, returns 200 or 500
## Database Architecture
| Database | File | Purpose |
|----------|------|---------|
| Primary | `storage/production.sqlite3` | Application data (newspapers, editions, stories) |
| Cache | `storage/production_cache.sqlite3` | Solid Cache store |
| Queue | `storage/production_queue.sqlite3` | Solid Queue job storage |
| Cable | `storage/production_cable.sqlite3` | Solid Cable pub/sub |
- `newspapers` — name
- `editions` — newspaper_id (FK), year, season (enum: spring/summer/autumn/winter), day (1–90), volume, issue_number, attention_bar, published
- `stories` — edition_id (FK, nullable), story_type (enum: major/secondary/tertiary/advertisement), position, headline, body, supertitle, subtitle, author, quote, quote_origin, summary_ticker
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
