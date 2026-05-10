# Phase 1: Production Security - Pattern Map

**Mapped:** 2026-05-10
**Files analyzed:** 2
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `config/environments/production.rb` | config | request-response | `config/environments/development.rb` | role-match |
| `config/initializers/content_security_policy.rb` | config | request-response | `config/initializers/filter_parameter_logging.rb` | role-match |

---

## Pattern Assignments

### `config/environments/production.rb` (config, request-response)

**Change type:** Uncomment three existing lines. No new code is introduced — the lines already exist with correct syntax and comments explaining each one.

**Analog:** `config/environments/development.rb`

**File structure pattern** (lines 1–3, production.rb):
```ruby
require "active_support/core_ext/integer/time"

Rails.application.configure do
```
All environment files follow the same `Rails.application.configure do ... end` block wrapper.

**Lines to uncomment** (production.rb lines 28–34):
```ruby
# Assume all access to the app is happening through a SSL-terminating reverse proxy.
# config.assume_ssl = true

# Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
# config.force_ssl = true

# Skip http-to-https redirect for the default health check endpoint.
# config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
```

**Target state after edit** (these three lines become live config, comments above each line are retained):
```ruby
# Assume all access to the app is happening through a SSL-terminating reverse proxy.
config.assume_ssl = true

# Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
config.force_ssl = true

# Skip http-to-https redirect for the default health check endpoint.
config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }
```

**Ordering note:** `assume_ssl` must appear before `force_ssl` in the file (it already does in the scaffold — match that order). `ssl_options` follows immediately after.

---

### `config/initializers/content_security_policy.rb` (config, request-response)

**Change type:** Replace the entirely-commented scaffold with a live CSP definition. The file structure must remain a single `Rails.application.configure do ... end` block (matching the style of every other initializer that uses `configure`).

**Analog:** `config/initializers/filter_parameter_logging.rb` (lines 1–8)

The active initializer pattern in this project uses the top-level `Rails.application.config` accessor directly, no `Rails.application.configure` wrapper — but the CSP scaffold already uses the `configure` block form, which is correct for `content_security_policy` since it is a block-style config method. Keep the `configure` wrapper.

**File-level comment pattern** (sourced from the existing CSP scaffold header, lines 1–5):
```ruby
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header
```
Retain this header verbatim.

**Target state — complete replacement:**
```ruby
# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data
    policy.img_src     :self, :data
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self
  end

  # Generate a per-request nonce for script-src and style-src.
  # Importmap renders an inline <script type="importmap"> tag that requires
  # this nonce; Rails injects it automatically via javascript_importmap_tags.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
```

**Directive rationale (for planner reference):**
- `default_src :self` — restrictive baseline; no CDN assets are loaded
- `font_src :self, :data` — allows data-URI fonts if any CSS embeds them; no external font CDN in use
- `img_src :self, :data` — allows data-URI images (common for CSS backgrounds); no external image CDN
- `object_src :none` — no Flash or plugin embeds; standard lockdown
- `script_src :self` — nonce generator adds `'nonce-XYZ'` to this directive automatically at request time, covering the importmap inline `<script>` block; `:https` is intentionally omitted because no external scripts are loaded
- `style_src :self` — nonce covers any inline `<style>` injected by Rails helpers; no `'unsafe-inline'` needed
- No `'unsafe-inline'` anywhere — decision D-04 explicitly prohibits it
- No `content_security_policy_report_only` — decision D-05 mandates enforcement from day one
- Alpine.js is loaded via importmap (an external JS file served from `:self`), so no special `script-src` relaxation is needed; Alpine's `x-` directives are HTML attributes, not inline scripts

**Nonce wiring — how it connects to the layout:**
`app/views/layouts/application.html.erb` already contains `<%= csp_meta_tag %>` (line 10) and `<%= javascript_importmap_tags %>` (line 23). Rails automatically injects the nonce into the importmap `<script>` tag when `content_security_policy_nonce_directives` includes `script-src`. No layout changes required.

---

## Shared Patterns

### Initializer File Structure
**Source:** `config/initializers/filter_parameter_logging.rb` (lines 1–8)
**Apply to:** `config/initializers/content_security_policy.rb`
```ruby
# Be sure to restart your server when you modify this file.

# [description comment]
Rails.application.config.[setting] ...
```
All initializers in this project begin with the `# Be sure to restart your server` comment. Retain it.

### Environment Config Block Structure
**Source:** `config/environments/production.rb` (lines 1–3, 90)
**Apply to:** `config/environments/production.rb` (no structural change — uncomment only)
```ruby
require "active_support/core_ext/integer/time"

Rails.application.configure do
  # ... settings ...
end
```
No wrappers, modules, or class definitions — bare `Rails.application.configure` block.

---

## No Analog Found

None. Both files exist in the codebase; the work is modification of existing files, not creation of new ones.

---

## Metadata

**Analog search scope:** `config/environments/`, `config/initializers/`, `app/views/layouts/`, `config/importmap.rb`
**Files scanned:** 8
**Pattern extraction date:** 2026-05-10
