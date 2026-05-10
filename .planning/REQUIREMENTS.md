# Requirements: Zeitgeist Press

**Defined:** 2026-05-10
**Core Value:** Readers can browse published newspaper editions and read the stories within them

## v1 Requirements

Requirements for the foundational milestone: production security, test coverage, and first HTTP-accessible page.

### Security

- [ ] **SEC-01**: `config.force_ssl = true` enabled in production config
- [ ] **SEC-02**: `config.assume_ssl = true` enabled in production config
- [ ] **SEC-03**: Content Security Policy initializer active with a sane default policy for a read-only Rails app

### Testing

- [ ] **TEST-01**: Newspaper model tests cover name presence validation and has_many :editions association
- [ ] **TEST-02**: Edition model tests cover season enum values, day numericality (1–90), year/season/day/volume/issue_number presence, and published flag default
- [ ] **TEST-03**: Story model tests cover story_type enum values, optional edition association (edition_id nullable), and story_type/headline/body presence validations

### Web

- [ ] **WEB-01**: NewspapersController exists with an index action that fetches all newspapers
- [ ] **WEB-02**: Root route (/) is wired to newspapers#index
- [ ] **WEB-03**: app/views/newspapers/index.html.erb renders a list of newspaper names (minimal, functional)

## v2 Requirements

Deferred to future milestones. Not in current roadmap.

### Reader Experience

- **READ-01**: Edition listing page for a selected newspaper
- **READ-02**: Story reader view for a selected edition (with attention bar, story layout by type)
- **READ-03**: Published-only filter on editions (hide drafts from readers)

### AI Generation

- **AI-01**: AI-assisted story generation via Anthropic Claude API (M2 milestone)
- **AI-02**: Story draft review and edit workflow

### Admin

- **ADMIN-01**: Newspaper creation and management UI
- **ADMIN-02**: Edition creation and publication workflow
- **ADMIN-03**: Story creation and editing UI

## Out of Scope

| Feature | Reason |
|---------|--------|
| Authentication / login | No user accounts needed for a read-only newspaper browser |
| PostgreSQL | Stack constraint — SQLite + Solid* gems for all environments |
| RSpec / FactoryBot | Minitest + YAML fixtures matches existing project convention |
| Node.js / Webpack | Importmap + Stimulus only — no bundler |
| Mobile app | Web-first; mobile not in scope |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEC-01 | Phase 1 | Pending |
| SEC-02 | Phase 1 | Pending |
| SEC-03 | Phase 1 | Pending |
| TEST-01 | Phase 2 | Pending |
| TEST-02 | Phase 2 | Pending |
| TEST-03 | Phase 2 | Pending |
| WEB-01 | Phase 3 | Pending |
| WEB-02 | Phase 3 | Pending |
| WEB-03 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 9 total
- Mapped to phases: 9
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-10*
*Last updated: 2026-05-10 after initial definition*
