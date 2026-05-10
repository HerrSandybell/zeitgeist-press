# Zeitgeist Press

A newspaper front page archive for a gaslight-era tabletop RPG campaign.

## Concept

Each newspaper edition contains several stories slotted into a fixed front page layout. Stories that overflow their allotted space show a "Continued on page #" link, which opens an overlay displaying the full story as a newspaper cutout.

## Tech Stack

- **Ruby on Rails** — backend, routing, data
- **Hotwire Turbo Streams** — dynamic page updates without full reloads
- **Alpine.js** — lightweight interactivity (overlays, toggles)
- **Semantic Tokens** — design system foundation
- **SQLite** — database (development)

## Data Model

### Newspaper
| Field | Type | Notes |
|-------|------|-------|
| name | string | |

### Edition
| Field | Type | Notes |
|-------|------|-------|
| newspaper_id | foreign key | |
| year | integer | |
| season | enum | spring, summer, autumn, winter |
| day | integer | 1–90 |
| volume | integer | |
| issue_number | integer | |
| attention_bar | string | optional — the bold banner across the top |

### Story
| Field | Type | Notes |
|-------|------|-------|
| edition_id | foreign key | |
| story_type | enum | major, secondary, tertiary, advertisement |
| position | integer | ordering within the edition |
| headline | string | |
| body | text | |
| supertitle | string | optional — e.g. "A Dispatch from the Cultural Front" |
| subtitle | string | optional — e.g. "The Guild Knew They Were Coming..." |
| author | string | optional |
| quote | text | optional |
| quote_origin | string | optional |
| summary_ticker | string | optional — e.g. "Officers Killed — Twice as Many Wounded —..." |

## Milestones

### M1 — Core (current)
- Data model: Edition, Story (with story types)
- Front page layout with stories slotted by type
- "Continued on page #" overlay for overflowing stories
- Seed data from existing editions

### M2 — Future
- In-app AI story generation via Claude API
- Chat window with tool-use to save approved editions/stories to the database
- Approval/edit flow before persisting

## Out of Scope (for now)

- Multiple newspapers/publications
- User accounts or authentication
- Image handling
