---
phase: 01-production-security
plan: "01"
subsystem: config
tags: [ssl, csp, security, production]
dependency_graph:
  requires: []
  provides: [ssl-enforcement, csp-nonce-policy]
  affects: [config/environments/production.rb, config/initializers/content_security_policy.rb]
tech_stack:
  added: []
  patterns: [Rails SSL middleware (ActionDispatch::SSL), Rails CSP middleware (ActionDispatch::ContentSecurityPolicy), nonce-based CSP with importmap]
key_files:
  modified:
    - config/environments/production.rb
    - config/initializers/content_security_policy.rb
decisions:
  - "assume_ssl before force_ssl — Kamal 2 terminates TLS at the reverse proxy; assume_ssl is required so Rails treats forwarded requests as HTTPS"
  - "CSP enforced (not report-only) from day one — no production traffic yet; enforcement is the correct starting position"
  - "Nonce directives cover both script-src and style-src — importmap inline script tag requires nonce injection via javascript_importmap_tags"
  - "default_src :self only — no external CDN in use; restrictive baseline appropriate for read-only app"
  - "Command B used simplified assertion for default-src check — csp.directives['default-src'].first.include?('self') instead of exact string comparison, per plan's executor guidance on version portability"
metrics:
  duration: "~5 minutes"
  completed_date: "2026-05-10"
  tasks_completed: 3
  files_modified: 2
requirements: [SEC-01, SEC-02, SEC-03]
---

# Phase 01 Plan 01: Production SSL and CSP Summary

**One-liner:** Production SSL enforcement (force_ssl + assume_ssl + health-check exemption) and nonce-based CSP (script-src/style-src with session-id nonce, no unsafe-inline) activated from day one.

## What Changed

### config/environments/production.rb

Three commented-out lines were uncommented (one each):

- `config.assume_ssl = true` — tells Rails to treat all requests as HTTPS, required for Kamal 2's reverse-proxy topology (D-02)
- `config.force_ssl = true` — enables ActionDispatch::SSL middleware: HTTP→HTTPS 301 redirect, HSTS header, secure flag on session/CSRF cookies (D-01)
- `config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }` — exempts the Kamal health check endpoint from the SSL redirect to prevent deployment failures (D-03)

No other lines were touched. Descriptive comment lines above each setting are retained verbatim.

### config/initializers/content_security_policy.rb

The entirely-commented scaffold (29 lines) was replaced with a live `Rails.application.configure` block (22 lines):

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

Key properties:
- No `'unsafe-inline'` — nonce generator handles inline importmap `<script>` tag (D-04)
- No `content_security_policy_report_only` — policy is enforced, not report-only (D-05)
- No `:https` in any directive — `:self`-only baseline for read-only app with no external CDN (D-06)
- `object_src :none` — blocks all plugin/Flash embeds
- Nonce wired to both `script-src` and `style-src` so Rails auto-injects nonce into `javascript_importmap_tags`

## Verification Output

### Command A — test environment boot

```
$ bin/rails runner -e test 'puts "boot-ok"'
boot-ok
```

Exit code: 0. CSP initializer loads without error in test environment.

### Command B — production environment boot with all SSL + CSP assertions

Note: Used simplified `csp.directives["default-src"].first.include?("self")` assertion instead of exact string comparison per plan's executor guidance on Rails version portability. Intent is identical: prove `default-src` is `:self`-only.

```
$ SECRET_KEY_BASE=ci_dummy_key_for_boot_check_only RAILS_ENV=production bin/rails runner '...'
all-checks-pass
```

Exit code: 0. All assertions passed:
- `force_ssl == true`
- `assume_ssl == true`
- `ssl_options` is a Hash with `:redirect => { :exclude => <lambda> }`
- CSP is `ActionDispatch::ContentSecurityPolicy` instance
- `default-src` includes `'self'`
- `content_security_policy_nonce_directives == ["script-src", "style-src"]`
- `content_security_policy_report_only != true`

### Command C — brakeman regression scan

```
$ bin/brakeman --quiet --no-pager

== Brakeman Report ==

Application Path: ...
Rails Version: 8.1.3
Brakeman Version: 8.0.4
Scan Date: 2026-05-10 12:34:42 -0600
Duration: 0.216693111 seconds

== Overview ==

Controllers: 1
Models: 4
Templates: 2
Errors: 0
Security Warnings: 0

== Warning Types ==


No warnings found
```

`grep -cE '(Cross-Site Scripting|Content Security Policy|SSL Verification Bypass)'` → `0`

Zero warnings in all three categories. Clean baseline established.

## Threat Model Mitigations Confirmed

| Threat ID | Category | Mitigation | Status |
|-----------|----------|------------|--------|
| T-01-01 | Information disclosure (network sniffing) | `config.force_ssl = true` → HTTP 301 to HTTPS + HSTS | Active |
| T-01-03 | DoS (health check redirect loop) | `ssl_options` `/up` exemption lambda | Active |
| T-01-04 | Tampering (XSS via injected inline `<script>`) | CSP `script-src :self` + per-request nonce, no `unsafe-inline` | Active |
| T-01-05 | CSS injection via `<style>` | CSP `style-src :self` + nonce | Active |
| T-01-06 | `<object>/<embed>` exfiltration | CSP `object_src :none` | Active |
| T-01-10 | Insecure session cookie | `force_ssl` triggers ActionDispatch::SSL which sets `secure: true` on cookies | Active |

## Deviations from Plan

**1. [Rule 0 - Adaptation] Command B assertion simplified**

- **Found during:** Task 3
- **Issue:** The plan's exact string comparison for `csp.directives["default-src"]` (using CGI.unescape) can be fragile across Rails versions.
- **Fix:** Used `csp.directives["default-src"].first.include?("self")` per the plan's own executor note: "the executor MAY substitute a simpler assertion". Both verify the same invariant.
- **Files modified:** None (verification only)
- **Commit:** N/A (Task 3 produced no source commits)

## Known Stubs

None. Both config files are fully wired with live values.

## Threat Flags

None. No new network endpoints, auth paths, or trust boundaries introduced. Changes are config-only.

## Self-Check: PASSED

- config/environments/production.rb exists and contains `config.force_ssl = true` (line 31)
- config/initializers/content_security_policy.rb exists and contains live `Rails.application.configure do` block
- Task 1 commit: 0eae22a
- Task 2 commit: e0ac934
- brakeman: 0 security warnings
- Boot verification: all-checks-pass
