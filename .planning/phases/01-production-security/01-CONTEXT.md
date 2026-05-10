# Phase 1: Production Security - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Enabling SSL enforcement and defining a Content Security Policy in production configuration. The two changes are purely config-level: uncommenting two lines in `config/environments/production.rb` and implementing the commented-out `config/initializers/content_security_policy.rb` initializer. No controllers, views, models, or routes are touched.

</domain>

<decisions>
## Implementation Decisions

### SSL Enforcement
- **D-01:** Uncomment `config.force_ssl = true` in `config/environments/production.rb`
- **D-02:** Uncomment `config.assume_ssl = true` in `config/environments/production.rb` — Kamal 2 deploys behind a reverse proxy, so this is the correct setting (not force_ssl alone)
- **D-03:** Uncomment `config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }` — exclude the Kamal health check endpoint from SSL redirect to prevent deployment failures

### Content Security Policy
- **D-04:** Use nonces for inline scripts — do NOT use `'unsafe-inline'`. Enable `config.content_security_policy_nonce_generator` and `config.content_security_policy_nonce_directives`. Importmap renders an inline `<script type="importmap">` tag that requires a nonce under a strict CSP.
- **D-05:** Enforce CSP directly from day one — do not use `content_security_policy_report_only`. The app has no production traffic yet; enforcement is the right starting position.
- **D-06:** CSP policy scope: read-only Rails app with Importmap + Stimulus, no external CDN assets. A restrictive default is appropriate: `default_src :self`, relax only what's needed (`font_src`, `img_src` can include `:data` for inline images).

### Claude's Discretion
- Exact CSP directive values (e.g., whether `style_src` needs `:unsafe-inline` for any Rails UJS or Stimulus behavior) — implement what's appropriate for a read-only app with no user-generated content and no forms.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Configuration Files to Modify
- `config/environments/production.rb` — SSL settings (force_ssl, assume_ssl, ssl_options) are commented out; uncomment all three
- `config/initializers/content_security_policy.rb` — entire file is commented-out scaffold; implement with nonces

### Project Constraints
- `.planning/REQUIREMENTS.md` §Security — SEC-01, SEC-02, SEC-03 are the acceptance criteria for this phase
- `.planning/ROADMAP.md` §Phase 1 — Success criteria and phase boundaries

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `config/initializers/content_security_policy.rb` — existing file with commented-out scaffold; modify in place, do not create a new file

### Established Patterns
- Importmap + Stimulus stack means no Node bundler; inline script handling is via Rails' `content_security_policy_nonce_generator` helper, not Webpack nonce plugins
- Kamal 2 deployment is behind a reverse proxy — `assume_ssl` is the correct SSL config, not terminating TLS at the Rails process

### Integration Points
- `config/environments/production.rb` — two SSL lines to uncomment plus the ssl_options health check exemption
- `config/initializers/content_security_policy.rb` — replace commented block with live CSP definition using nonces

</code_context>

<specifics>
## Specific Ideas

No specific requirements beyond what the requirements define — open to standard Rails 8.1 CSP approach with nonces.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Production Security*
*Context gathered: 2026-05-10*
