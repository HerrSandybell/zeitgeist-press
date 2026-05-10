# Conventions

## Naming

- Standard Rails conventions: snake_case for files, methods, DB columns; CamelCase for classes
- Enum columns use integer-backed values defined inline in models
- No custom naming deviations detected

## Code Style & Linting

- RuboCop with `rubocop-rails-omakase` ruleset (Basecamp's opinionated defaults)
- No custom overrides — `.rubocop.yml` inherits the gem config as-is

## Common Patterns

- Thin models with inline validations and enum definitions
- Idempotent seeds via `find_or_create_by!`
- No service objects, decorators, or presenters observed — standard Rails MVC only
- No ActiveRecord concerns or mixins detected

## Error Handling

- No custom error handling beyond Rails defaults
- No custom exception classes or rescue middleware

## Logging

- Default Rails logger — no custom log formatting or structured logging

## Documentation Style

- Minimal inline comments
- No YARD or RDoc-style documentation observed

## Git Conventions

- Short imperative commit messages (Rails scaffold style)
- Single `main` branch — no feature branch convention observed
- No PR templates or commit hooks detected
