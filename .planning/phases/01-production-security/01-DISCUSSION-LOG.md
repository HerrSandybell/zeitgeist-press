# Phase 1: Production Security - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 1-production-security
**Areas discussed:** Nonce strategy, CSP enforcement mode, Health check SSL exemption

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Nonce strategy | Importmap renders inline script tags — how to allow them under a strict CSP | ✓ |
| CSP enforcement mode | Report-only first vs. direct enforcement | ✓ |
| Health check SSL exemption | Whether /up should be excluded from the SSL redirect | ✓ |

**User's choice:** Accepted recommended decisions across all three areas
**Notes:** User asked for a recommendation appropriate for "a basic app for a few people" — all three recommendations were accepted as-is.

---

## Nonce strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Use nonces | Enable content_security_policy_nonce_generator — inline scripts get a per-request nonce; importmap tag works cleanly | ✓ |
| unsafe-inline | Allow inline scripts via 'unsafe-inline' — simpler but defeats the purpose of CSP | |
| SHA256 hash | Hash the importmap script tag content — brittle as content changes with routes | |

**User's choice:** Use nonces
**Notes:** Recommendation accepted. Rails 8.1 has native nonce support; importmap + Stimulus work cleanly with nonces.

---

## CSP Enforcement Mode

| Option | Description | Selected |
|--------|-------------|----------|
| Enforce directly | Start enforcing from day one — violations block immediately | ✓ |
| Report-only first | Observe violations without blocking — then switch to enforcement | |

**User's choice:** Direct enforcement
**Notes:** No production traffic yet, tiny user base — nothing to observe in report-only mode.

---

## Health Check SSL Exemption

| Option | Description | Selected |
|--------|-------------|----------|
| Exclude /up | Exempt Kamal health check from SSL redirect via ssl_options | ✓ |
| No exemption | Enforce SSL for all endpoints including /up | |

**User's choice:** Exclude /up
**Notes:** Kamal health checks run over HTTP — redirecting them to HTTPS can stall deployments even for small apps.

---

## Claude's Discretion

- Exact CSP directive values for `style_src`, `font_src`, `img_src` — implement what's appropriate for a read-only app with no user-generated content and no forms. `'unsafe-inline'` for style is acceptable if Stimulus or Rails UJS requires it.

## Deferred Ideas

None — discussion stayed within phase scope.
