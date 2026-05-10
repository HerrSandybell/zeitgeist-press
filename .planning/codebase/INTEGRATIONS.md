# External Integrations

**Analysis Date:** 2026-05-10

## Third-Party Services

No active third-party service integrations are present. The application is entirely self-contained with all infrastructure (database, cache, queue, websockets) handled by SQLite-backed Solid* gems.

**Planned (noted in CLAUDE.md, not yet implemented):**
- **Anthropic Claude API** — in-app AI story generation via Claude API (M2 milestone); chat window with tool-use to save approved editions/stories to the database. No SDK or API client code exists yet.

## Environment Variables (by integration)

**Rails Core:**
- `RAILS_MASTER_KEY` — decrypts `config/credentials.yml.enc`; injected as Kamal secret at deploy time
- `RAILS_ENV` — environment selector (`development`, `test`, `production`)
- `RAILS_MAX_THREADS` — Puma thread count and DB connection pool size (default: 3 in puma.rb, 5 in database.yml)
- `RAILS_LOG_LEVEL` — optional log verbosity override (commented out in `config/deploy.yml`)
- `SECRET_KEY_BASE_DUMMY` — used only during Docker asset precompile build step

**Server / Process:**
- `PORT` — Puma listen port (default: 3000)
- `PIDFILE` — optional Puma PID file path
- `WEB_CONCURRENCY` — number of Puma worker processes (default: 1)

**Solid Queue:**
- `SOLID_QUEUE_IN_PUMA` — when `true`, runs Solid Queue supervisor inside the Puma process (set to `true` in `config/deploy.yml`)
- `JOB_CONCURRENCY` — number of Solid Queue worker processes (default: 1, configured in `config/queue.yml`)

**Not present / not configured:**
- No `STRIPE_*`, `SENDGRID_*`, `POSTMARK_*`, `AWS_*`, `GCS_*`, `REDIS_URL`, `SENTRY_*`, or any other third-party service credentials

## Webhooks

**Inbound:** None

**Outbound:** None

No webhook endpoints are defined in `config/routes.rb` and no outbound HTTP clients (Faraday, HTTParty, Net::HTTP wrappers) are present in the codebase.

## OAuth / SSO Providers

None. Authentication is explicitly out of scope per `CLAUDE.md`. No Devise, OmniAuth, or OAuth gems are in the Gemfile.

## Storage & CDN

**File Storage:**
- Active Storage configured for **local disk only** (`config/storage.yml`)
  - Development/test: `storage/` directory in project root
  - Production: same path, persisted via Docker volume `zeitgeist_press_storage:/rails/storage`
- S3 (`amazon`) and GCS (`google`) service configs are present but commented out in `config/storage.yml`
- No CDN configured

**Database Storage:**
- All data stored in SQLite files within the `storage/` Docker volume:
  - `storage/production.sqlite3` — primary application data
  - `storage/production_cache.sqlite3` — Solid Cache
  - `storage/production_queue.sqlite3` — Solid Queue
  - `storage/production_cable.sqlite3` — Solid Cable

**Container Registry:**
- `localhost:5555` — local registry placeholder in `config/deploy.yml`; intended to be replaced with Docker Hub, GHCR, DigitalOcean, or similar before production deploy

---

*Integration audit: 2026-05-10*
