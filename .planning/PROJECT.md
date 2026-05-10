# Zeitgeist Press

## What This Is

A Rails 8.1 web app for publishing and browsing historical newspaper editions. Built around a multi-publication model: a Newspaper publishes Editions, each Edition contains typed Stories (major headlines, secondary pieces, tertiary items, and advertisements). The seed data is set in a fictional steampunk world (Zeitgeist TTRPG), but the platform is a general newspaper publisher.

## Core Value

Readers can browse published newspaper editions and read the stories within them — the publishing model is solid, the reading experience does not exist yet.

## Requirements

### Validated

- ✓ Newspaper model (name, has_many editions) — existing
- ✓ Edition model (newspaper_id, volume, issue_number, year, season/day, attention_bar, published) — existing
- ✓ Story model (edition_id optional, story_type enum, headline, body, subtitle, supertitle, summary_ticker, author, quote, quote_origin, position) — existing
- ✓ SQLite-backed database with 5 migrations applied — existing
- ✓ Solid* gems for queue/cache/cable (separate SQLite DBs) — existing
- ✓ Kamal 2 + Docker deployment config — existing
- ✓ Seed data: "Pryce of Progress" newspaper, one published edition, 8 stories — existing

### Active

- [x] Production SSL enforced (force_ssl + assume_ssl enabled) — Validated in Phase 01: production-security
- [x] Content Security Policy defined and active in production — Validated in Phase 01: production-security
- [ ] Newspaper model fully tested (name validation, edition association)
- [ ] Edition model fully tested (season enum, day range validation, volume/issue presence, published flag)
- [ ] Story model fully tested (story_type enum, optional edition, headline/body/type presence)
- [ ] Newspapers index page lists all newspapers at root (/)
- [ ] Newspapers controller wired to root route

### Out of Scope

- Authentication / user accounts — no login needed for a read-only newspaper browser
- Edition and story management UI — read-only browsing first; admin features later
- AI story generation — planned for M2 milestone
- Payments, subscriptions — out of scope for this project

## Context

Brownfield Rails 8.1.3 / Ruby 3.3.5 app. The domain model (Newspaper → Edition → Story) is complete and seeded with rich fictional content. The app is currently unreachable via HTTP beyond the `/up` health check — root route is commented out, no domain controllers or views exist.

Codebase map produced 2026-05-10 via `/gsd-map-codebase`. Key findings:
- SSL/CSP disabled in production config (security risk)
- Zero real tests (all model test files are scaffold stubs)
- No controllers, routes, or views beyond health check
- Anthropic Claude API integration planned but not yet started

## Constraints

- **Tech stack**: Rails 8.1 / Ruby 3.3.5 / SQLite — do not introduce PostgreSQL or Node.js build pipeline
- **SSL**: Kamal 2 deploys behind a reverse proxy — `assume_ssl` is the correct setting, not raw `force_ssl` alone
- **Testing**: Minitest + YAML fixtures only (no RSpec, no FactoryBot)
- **JS**: Importmap + Stimulus — no bundler

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Root route = Newspapers list | Natural entry point for a multi-publication app | — Pending |
| Force SSL + basic CSP in one phase | Security gaps are high priority; both are config-level changes | — Pending |
| YAML fixtures for tests (no FactoryBot) | Matches existing project convention | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-10 — Phase 01 complete: SSL enforcement + nonce-based CSP active in production*
