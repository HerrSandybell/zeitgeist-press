---
phase: 01-production-security
reviewed: 2026-05-10T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - config/environments/production.rb
  - config/initializers/content_security_policy.rb
findings:
  critical: 3
  warning: 3
  info: 0
  total: 6
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-05-10
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Reviewed the production environment configuration and the Content Security Policy initializer. Both files contain substantive security defects — not style issues. The most severe is that the CSP nonce is derived from the session ID rather than a fresh random value, which renders the nonce mechanism useless against an attacker who can observe or fix the session. Two additional critical gaps exist: DNS rebinding protection is commented out entirely, and the CSP is missing a `form-action` directive (which does not inherit from `default-src` in browsers). Three warnings round out the review: a placeholder mailer hostname that will break all generated URLs in production, local Active Storage that does not survive container redeployment, and no `frame-ancestors` directive to enforce clickjacking protection via CSP.

## Critical Issues

### CR-01: Session ID Used as CSP Nonce Breaks the Security Model

**File:** `config/initializers/content_security_policy.rb:20`
**Issue:** The nonce generator returns `request.session.id.to_s`. A CSP nonce must be a fresh, unguessable random value generated per request. The session ID is stable across many requests for the same user; any attacker who can observe or control the session ID (via session fixation, network sniffing before a TLS hop, or leakage through a Referer header) can predict the nonce value and inject matching inline scripts, completely defeating the purpose of nonce-based CSP.
**Fix:**
```ruby
# Use a cryptographically random value — the Rails default recommendation
config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
```

---

### CR-02: DNS Rebinding Protection Disabled in Production

**File:** `config/environments/production.rb:83-89`
**Issue:** The `config.hosts` allowlist is entirely commented out. Rails' `ActionDispatch::HostAuthorization` middleware is therefore inactive, accepting requests with any `Host` header value. This enables DNS rebinding attacks — an attacker controls a domain that briefly resolves to the server's IP, then issues requests to the app through a victim's browser. It also allows host header injection into generated URLs (password reset links, absolute asset URLs, mailer links).
**Fix:**
```ruby
config.hosts = [
  "zeitgeist-press.example.com",   # replace with actual production hostname
  /.*\.zeitgeist-press\.example\.com/
]

# Keep health check excluded so the load balancer probe still works
config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
```

---

### CR-03: CSP Missing `form-action` Directive

**File:** `config/initializers/content_security_policy.rb:8-15`
**Issue:** The `form-action` CSP directive is not set. Unlike most other fetch directives, `form-action` does **not** fall back to `default-src` — browsers treat an absent `form-action` as unrestricted (`*`). This means any form on the site can be submitted to an attacker-controlled origin, enabling form-hijacking and phishing attacks that extract user-submitted data.
**Fix:**
```ruby
config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, :data
  policy.img_src     :self, :data
  policy.object_src  :none
  policy.script_src  :self
  policy.style_src   :self
  policy.form_action :self          # add this — prevents cross-origin form submission
  policy.frame_ancestors :none      # also add — see WR-03
end
```

---

## Warnings

### WR-01: Mailer Host Is a Placeholder — All Generated URLs Will Be Wrong

**File:** `config/environments/production.rb:61`
**Issue:** `config.action_mailer.default_url_options = { host: "example.com" }` uses the literal placeholder domain. Any URL generated inside a mailer template (password reset, notification, etc.) will point to `example.com` instead of the real application host, making those links non-functional.
**Fix:**
```ruby
config.action_mailer.default_url_options = { host: ENV.fetch("APPLICATION_HOST") }
```
Set `APPLICATION_HOST` in the Kamal secrets/env config alongside `RAILS_MASTER_KEY`.

---

### WR-02: Active Storage on Local Disk Will Lose Uploads on Redeployment

**File:** `config/environments/production.rb:25`
**Issue:** `config.active_storage.service = :local` stores uploads on the container filesystem. Kamal redeploys replace the container, so any uploaded files written between deploys will be lost. This is a data loss risk for any feature that uses Active Storage (currently image_processing is in the Gemfile).
**Fix:** Use a persistent volume mount or an object storage backend (S3, GCS). If uploads are truly not used by any active feature yet, add a comment to that effect so the risk is acknowledged, not invisible:
```ruby
# NOTE: Local storage intentionally — Active Storage not used in M1.
# Switch to :amazon or :google before enabling any upload features.
config.active_storage.service = :local
```

---

### WR-03: CSP Missing `frame-ancestors` — Clickjacking Only Partially Mitigated

**File:** `config/initializers/content_security_policy.rb:8-15`
**Issue:** The CSP policy does not include a `frame-ancestors` directive. Rails sets `X-Frame-Options: SAMEORIGIN` by default, which provides some clickjacking mitigation in older browsers, but `frame-ancestors` is the modern CSP replacement that supersedes `X-Frame-Options` in all current browsers. Without it, the CSP provides no clickjacking protection — only the legacy header does.
**Fix:**
```ruby
policy.frame_ancestors :none   # or :self if embedding in own iframes is needed
```
(Can be added in the same block as CR-03's `form_action` fix above.)

---

_Reviewed: 2026-05-10_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
