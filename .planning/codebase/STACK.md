# Tech Stack

**Analysis Date:** 2026-05-10

## Runtime & Language

- **Ruby 3.3.5** — application language (pinned in `.ruby-version`)
- **Bundler 2.5.16** — gem dependency manager (lockfile present: `Gemfile.lock`)

## Core Frameworks

- **Ruby on Rails 8.1.3** — full-stack web framework; all Rails components in use (ActionCable, ActionMailbox, ActionMailer, ActionText, ActiveJob, ActiveStorage, ActiveRecord)
- **Hotwire Turbo 2.0.23** (`turbo-rails`) — SPA-like page updates via Turbo Streams/Frames, no full reloads
- **Hotwire Stimulus 1.3.4** (`stimulus-rails`) — modest JS framework for behavior attached to HTML
- **Alpine.js 3.15.12** — lightweight inline interactivity (overlays, toggles); loaded via importmap

## Key Dependencies

**Web / Server:**
- `puma` 8.0.1 — multi-threaded application server; default 3 threads (`RAILS_MAX_THREADS`)
- `thruster` 0.1.20 — HTTP caching/compression proxy in front of Puma in production
- `propshaft` 1.3.2 — asset pipeline (replaces Sprockets)
- `importmap-rails` 2.2.3 — ESM importmaps for JavaScript (no bundler/Node required)
- `jbuilder` 2.14.1 — JSON view templates

**Database:**
- `sqlite3` 2.9.4 — ActiveRecord adapter; four SQLite databases in production (primary, cache, queue, cable)

**Background Jobs:**
- `solid_queue` 1.4.0 — DB-backed job queue (SQLite); runs inside Puma process in single-server mode via `plugin :solid_queue`
- `solid_cable` 3.0.12 — DB-backed Action Cable adapter (SQLite)

**Caching:**
- `solid_cache` 1.0.10 — DB-backed Rails cache (SQLite)

**Image Processing:**
- `image_processing` 1.14.0 — Active Storage variants
- `ruby-vips` 2.3.0 / `mini_magick` 5.3.1 — image processing backends; `libvips` installed in Docker image

**Deployment:**
- `kamal` 2.11.0 — Docker-based deploy tool; config at `config/deploy.yml`

**Security / Static Analysis:**
- `brakeman` 8.0.4 — Rails security scanner (run in CI)
- `bundler-audit` 0.9.3 — gem vulnerability scanner (run in CI)

**Testing:**
- `minitest` 6.0.6 — test runner (built into Rails)
- `capybara` 3.40.0 — system/integration test DSL
- `selenium-webdriver` 4.43.0 — browser automation for system tests

**Development:**
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
  - Dockerfile at project root
  - jemalloc (`libjemalloc2`) enabled via `LD_PRELOAD` for reduced memory usage
  - libvips installed for image processing
  - Non-root user `rails` (uid/gid 1000)
  - Exposes port 80; started via `thruster`
- **Kamal 2** — deployment orchestration; config at `config/deploy.yml`
  - Target: single VPS (placeholder IP `192.168.0.1`)
  - Container registry: `localhost:5555` (local registry placeholder)
  - Persistent volume: `zeitgeist_press_storage:/rails/storage` (SQLite files + Active Storage)
  - Builder arch: `amd64`
  - Secrets sourced from `.kamal/secrets`
- **GitHub Actions** — CI pipeline at `.github/workflows/ci.yml`
  - Jobs: `scan_ruby` (Brakeman + bundler-audit), `scan_js` (importmap audit), `lint` (RuboCop), `test` (minitest), `system-test` (Capybara/Selenium)
  - Triggers: push to `main`, all pull requests
  - `ruby/setup-ruby@v1` with `bundler-cache: true`
  - System test screenshots uploaded as artifacts on failure
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

---

*Stack analysis: 2026-05-10*
