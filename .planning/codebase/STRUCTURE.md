# Code Structure

## Directory Layout

```
zeitgeist-press/
├── app/
│   ├── assets/stylesheets/    # application.css (no asset pipeline build step)
│   ├── controllers/           # application_controller.rb only — no domain controllers yet
│   ├── helpers/               # application_helper.rb (empty)
│   ├── javascript/
│   │   └── controllers/       # Stimulus controllers (hello_controller stub only)
│   ├── jobs/                  # application_job.rb (base class only)
│   ├── mailers/               # application_mailer.rb (base class only)
│   ├── models/                # 3 domain models + application_record.rb base
│   └── views/layouts/         # application.html.erb, mailer layouts, PWA manifest
├── config/
│   ├── environments/          # development.rb, production.rb, test.rb
│   ├── initializers/          # CSP (commented out), asset pins, filter logging
│   ├── deploy.yml             # Kamal 2 deployment config
│   ├── importmap.rb           # JS importmap (no Node.js build)
│   └── routes.rb              # Only health check route wired; root commented out
├── db/
│   ├── migrate/               # 5 migrations (3 create tables, 2 alter)
│   ├── schema.rb              # Canonical schema source
│   ├── seeds.rb               # Seed data
│   ├── queue_schema.rb        # SolidQueue schema (separate SQLite DB)
│   ├── cache_schema.rb        # SolidCache schema (separate SQLite DB)
│   └── cable_schema.rb        # ActionCable/SolidCable schema (separate SQLite DB)
├── test/
│   ├── fixtures/              # YAML fixtures for all 3 models
│   └── models/                # 3 model test files (scaffold stubs, all commented out)
└── Dockerfile / config/deploy.yml  # Kamal 2 / Docker deployment
```

## Key Namespaces / Modules

| Model | Responsibility |
|-------|---------------|
| `Newspaper` | Top-level publication entity; owns editions |
| `Edition` | A single issue of a newspaper (seasonal, volume/issue numbered, publishable) |
| `Story` | An article within an edition; typed (major/secondary/tertiary/advertisement), optionally unassigned |

No service objects, presenters, or other non-MVC namespaces exist yet.

## Domain vs Infrastructure

- **Domain**: `app/models/` — Newspaper → Edition → Story hierarchy
- **Infrastructure**: Solid* gems (queue, cache, cable) backed by separate SQLite databases; Kamal 2 for deployment
- **No domain controllers or views yet** — the data model is complete but no HTTP-accessible interface exists

## Entry Points

- `config/environment.rb` → `config/application.rb` → Rails boot
- `config/puma.rb` — web server configuration
- Only HTTP endpoint: `GET /up` (health check via `rails/health#show`)
- Root route (`/`) is commented out

## Test Organization

- `test/models/` mirrors `app/models/` — one `_test.rb` per model
- `test/fixtures/` holds YAML data for all 3 models
- `test/controllers/`, `test/integration/`, `test/helpers/`, `test/mailers/` all exist but are empty (`.keep` only)

## Conventions

- Standard Rails MVC — no additional layers
- Importmap for JS (no bundler/Node)
- Separate SQLite databases per Solid* subsystem (not the main app DB)
- `find_or_create_by!` pattern in seeds for idempotency
