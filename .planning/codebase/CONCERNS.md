# Concerns & Technical Debt

## Security

| Severity | Location | Issue |
|----------|----------|-------|
| HIGH | `config/environments/production.rb` | `config.force_ssl` and `config.assume_ssl` are commented out — app will serve over HTTP in production |
| HIGH | `config/initializers/content_security_policy.rb` | Entire CSP initializer is commented out — no XSS browser-level mitigation |
| MEDIUM | `app/models/edition.rb` | No DB-level uniqueness constraint on (volume, issue_number, newspaper_id) — only model-level validation gap |
| MEDIUM | `app/models/story.rb` | No DB-level uniqueness on position within edition — duplicate positions possible via concurrent writes |

## Performance

| Severity | Location | Issue |
|----------|----------|-------|
| MEDIUM | DB / production config | SQLite in production has write concurrency limits; Solid* on SQLite means 4 separate DB files, each single-writer |
| LOW | `db/schema.rb` | No index on `editions.published` — once query volume grows, filtering published editions will be a full scan |
| LOW | `db/schema.rb` | No composite index on (newspaper_id, published) for the canonical "get published editions for newspaper" query |

## Technical Debt

| Severity | Location | Issue |
|----------|----------|-------|
| HIGH | `config/routes.rb` | Root route is commented out; no domain controllers or views exist — app is HTTP-inaccessible beyond the health check |
| MEDIUM | `app/javascript/controllers/hello_controller.js` | Scaffold-generated Stimulus stub not removed |
| LOW | `config/initializers/content_security_policy.rb` | Entire file is commented-out scaffold — either implement or delete |
| LOW | `config/initializers/inflections.rb` | Empty scaffold file |

## Test Coverage Gaps

| Severity | Location | Issue |
|----------|----------|-------|
| HIGH | `test/models/newspaper_test.rb` | All tests commented out — zero coverage for Newspaper model |
| HIGH | `test/models/edition_test.rb` | All tests commented out — zero coverage for Edition model (enums, validations, day range) |
| HIGH | `test/models/story_test.rb` | All tests commented out — zero coverage for Story model (enum, optional edition association) |
| HIGH | `test/controllers/` | Empty — no controller tests (none exist yet, but flagged for when controllers are added) |
| HIGH | `test/integration/` | Empty — no integration tests |

## Dependency Health

| Severity | Package | Issue |
|----------|---------|-------|
| LOW | `image_processing` | Gem is included (pulls in libvips/ImageMagick native deps) but Active Storage image variants are not used |

## Architectural Smells

| Severity | Location | Issue |
|----------|----------|-------|
| MEDIUM | `app/models/edition.rb` | No `published` scope on the model — callers must know to filter by `published: true`; risk of exposing draft editions |
| LOW | `app/models/story.rb` | `position` column has no model-level validation or ordering default — ordering behavior is implicit |

## Operational

| Severity | Location | Issue |
|----------|----------|-------|
| HIGH | Application-wide | No error tracking integration (no Sentry, Honeybadger, Rollbar, etc.) |
| MEDIUM | Application-wide | No backup strategy for SQLite databases (main + 3 Solid* DBs) |
| LOW | `config/recurring.yml` | Recurring job file exists (Kamal/SolidQueue) but is empty — placeholder only |

## Summary

The codebase is at an early data-model-only stage: the domain schema (Newspaper → Edition → Story) is solid and well-structured, but the app has no UI, no controllers, no routes beyond a health check, and zero real tests. The two most urgent priorities before adding features are: (1) **enable SSL and CSP in production** to address the high-severity security gaps, and (2) **write model tests** since all test files are empty scaffolds. The third priority is standing up the first controller/route so the application is actually reachable.
