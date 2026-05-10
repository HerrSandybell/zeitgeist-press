# Testing

## Frameworks

- Minitest via `ActiveSupport::TestCase`
- Parallel test workers enabled (default Rails 8 config)

## Test Types

- Model unit tests only (scaffold-generated stubs)
- No integration tests
- No system tests (CI runs `test:system` but no system test files exist)

## File Conventions

- `test/models/` mirrors `app/models/`
- Files named `<model>_test.rb`

## Fixtures & Factories

- YAML fixtures only (Rails default, in `test/fixtures/`)
- No FactoryBot or other factory library

## Mocking Strategy

- No mocking strategy established — test files are scaffold stubs with all tests commented out
- Zero real tests written

## Coverage

- No coverage tooling (no SimpleCov or equivalent)

## CI Setup

- GitHub Actions runs `bin/rails db:test:prepare test` and `test:system` on push/PR to `main`

## Gaps & Anti-Patterns

- **Critical gap**: All three model test files are scaffold-generated with every test body commented out — effectively zero test coverage
- No integration or request specs
- No system/feature tests despite CI configuration for them
- No coverage enforcement gates
