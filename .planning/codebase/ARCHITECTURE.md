# Architecture

<!-- refreshed: 2026-05-10 -->

**Analysis Date:** 2026-05-10

## Pattern & Style

Standard Rails MVC monolith. The application follows the conventional Rails layered approach:

```
Browser
   │
   ▼
Puma (web server) + Thruster (asset caching/X-Sendfile)
   │
   ▼
Rails Router  (`config/routes.rb`)
   │
   ▼
Controllers  (`app/controllers/`)
   │
   ▼
Models / ActiveRecord  (`app/models/`)
   │
   ▼
SQLite (primary DB)
```

Server-rendered HTML with progressive enhancement via Hotwire Turbo and Alpine.js. No separate API layer — all responses are HTML (with Turbo Streams for partial updates).

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

1. Browser requests a page
2. Puma/Thruster receives the request
3. Router (`config/routes.rb`) dispatches to the appropriate controller action
4. Controller queries models via ActiveRecord
5. ActiveRecord reads from SQLite (`storage/production.sqlite3`)
6. Controller renders an ERB view template (`app/views/`)
7. Turbo Drive intercepts navigation — only the `<body>` is swapped, no full reload

### Story Overflow (planned)

1. User clicks "Continued on page #" link in the front page layout
2. Alpine.js intercepts the click and opens an overlay
3. Overlay renders the full story content as a newspaper cutout

## Auth Model

No authentication or authorization. The application is a single-user archive tool with no login system. Per `CLAUDE.md`: "User accounts or authentication" is explicitly out of scope.

## Background Processing

Solid Queue (`gem "solid_queue"`) backed by a dedicated SQLite database (`storage/production_queue.sqlite3`).

- Config: `config/queue.yml`
- Workers: 3 threads, 1 process by default (controlled via `JOB_CONCURRENCY` env var)
- Dispatchers: 1, polling interval 1s, batch size 500
- Recurring jobs: `config/recurring.yml` — one production job clears finished Solid Queue job records hourly

No application-level jobs are defined yet beyond the infrastructure scaffold (`app/jobs/application_job.rb`).

## Caching

Solid Cache (`gem "solid_cache"`) backed by `storage/production_cache.sqlite3`.

- Config: `config/cache.yml`
- Max size: 256 MB
- Namespaced by Rails environment
- Fragment caching enabled in production (`config.action_controller.perform_caching = true`)
- Static assets cached with far-future expiry headers (1 year) via Thruster and Propshaft digest stamping
- Development/test: in-process memory cache (Solid Cache only activates in production)

## API Design

No external API. The application serves server-rendered HTML only. Routes are conventional Rails resource routes. Currently only the health check endpoint is explicitly defined:

- `GET /up` — Rails health check, returns 200 or 500

Root route and all resource routes are not yet wired (`config/routes.rb` has only the health check; all resource routing is pending implementation).

## Database Architecture

SQLite-based. In production, four separate SQLite databases handle different concerns:

| Database | File | Purpose |
|----------|------|---------|
| Primary | `storage/production.sqlite3` | Application data (newspapers, editions, stories) |
| Cache | `storage/production_cache.sqlite3` | Solid Cache store |
| Queue | `storage/production_queue.sqlite3` | Solid Queue job storage |
| Cable | `storage/production_cable.sqlite3` | Solid Cable pub/sub |

Development and test use a single SQLite file each (`storage/development.sqlite3`, `storage/test.sqlite3`).

Schema version: `2026_05_10_063906` (`db/schema.rb`)

**Domain schema:**
- `newspapers` — name
- `editions` — newspaper_id (FK), year, season (enum: spring/summer/autumn/winter), day (1–90), volume, issue_number, attention_bar, published
- `stories` — edition_id (FK, nullable), story_type (enum: major/secondary/tertiary/advertisement), position, headline, body, supertitle, subtitle, author, quote, quote_origin, summary_ticker

Stories can exist without an edition (`edition_id` is optional), allowing pre-draft story creation.

---

*Architecture analysis: 2026-05-10*
