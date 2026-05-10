# Roadmap: Zeitgeist Press

## Overview

Three focused phases to bring the app from its current skeleton state to a secure, tested, and HTTP-accessible baseline. Each phase addresses one concern: production security configuration, model test coverage, then the first real web page.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Production Security** - Enable SSL enforcement and Content Security Policy in production config
- [ ] **Phase 2: Model Test Coverage** - Write Minitest tests for all three domain models
- [ ] **Phase 3: First Web Page** - Wire the root route to a working Newspapers index page

## Phase Details

### Phase 1: Production Security
**Goal**: The production environment enforces SSL and defines a Content Security Policy
**Depends on**: Nothing (first phase)
**Requirements**: SEC-01, SEC-02, SEC-03
**Success Criteria** (what must be TRUE):
  1. `config.force_ssl = true` is present and active in `config/environments/production.rb`
  2. `config.assume_ssl = true` is present and active in `config/environments/production.rb`
  3. A CSP initializer exists in `config/initializers/` with a policy appropriate for a read-only Rails app
  4. The CSP initializer is loaded on boot without errors
**Plans**: 1 plan
Plans:
- [x] 01-01-PLAN.md — Enable SSL enforcement and activate nonce-based Content Security Policy

### Phase 2: Model Test Coverage
**Goal**: All three domain models have real Minitest tests covering validations, enums, and associations
**Depends on**: Phase 1
**Requirements**: TEST-01, TEST-02, TEST-03
**Success Criteria** (what must be TRUE):
  1. `rails test test/models/newspaper_test.rb` passes with tests for name presence and has_many :editions
  2. `rails test test/models/edition_test.rb` passes with tests for season enum, day range (1–90), year/season/day/volume/issue_number presence, and published flag default
  3. `rails test test/models/story_test.rb` passes with tests for story_type enum, nullable edition_id, and story_type/headline/body presence
  4. `rails test` exits green with zero failures and zero errors
**Plans**: 3 plans
Plans:
- [ ] 02-01-PLAN.md — Newspaper model tests (name presence, has_many editions) + meaningful newspapers.yml
- [ ] 02-02-PLAN.md — Edition model tests (season enum, day numericality, presence, published default) + label-string editions.yml
- [ ] 02-03-PLAN.md — Story model tests (story_type enum, optional edition, presence) + stories.yml with orphan fixture

### Phase 3: First Web Page
**Goal**: The app serves a real HTTP response at / listing all newspapers
**Depends on**: Phase 2
**Requirements**: WEB-01, WEB-02, WEB-03
**Success Criteria** (what must be TRUE):
  1. `GET /` returns HTTP 200 and renders without error
  2. The response body contains the name of every newspaper in the database
  3. `rails routes` shows `root` wired to `newspapers#index`
  4. `rails test` remains green after adding the controller and view
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Production Security | 0/1 | Not started | - |
| 2. Model Test Coverage | 0/3 | Not started | - |
| 3. First Web Page | 0/? | Not started | - |
