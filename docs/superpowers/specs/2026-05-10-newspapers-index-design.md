# Design: Newspapers Index (Root Page)

**Date:** 2026-05-10
**Scope:** First controller and view — newspapers list as plain text at the app root.

## Goal

Give the app a working root page. Render the list of newspapers from the database as plain text. This is the foundation for the reading experience and a clean first example of Rails MVC in this codebase.

## Architecture

Standard Rails MVC. No special patterns needed.

- **Controller:** `NewspapersController` in `app/controllers/newspapers_controller.rb`
- **Action:** `index` — fetches `Newspaper.all`, assigns to `@newspapers`
- **View:** `app/views/newspapers/index.html.erb` — iterates `@newspapers`, prints each `newspaper.name`
- **Route:** `root "newspapers#index"` in `config/routes.rb`

## Scope

- Render newspaper names as plain text. No styling, no partials, no pagination.
- One newspaper in seed data ("Pryce of Progress") — the list will have one entry.
- No filtering, sorting, or linking to editions (future work).

## Out of Scope

- Editions index or show pages
- Any styling or design system usage
- Turbo Frames / Turbo Streams (planned for later features)
