# Comment Section Design

**Date:** 2026-05-13
**Status:** Approved

## Overview

A live-updating comment section on each Edition page, styled as JRPG-style speech bubbles. Readers post comments as pre-seeded TTRPG characters chosen from a styled dropdown. No accounts, no login — character identity is picked per comment and persisted in `localStorage`. New comments broadcast instantly to all connected browsers via Turbo Streams over Action Cable.

## Data Model

### Character
| Field | Type | Notes |
|-------|------|-------|
| name | string | required |
| emoji | string | portrait icon shown in picker and bubble (e.g. `"🕵️"`) |

- Seeded from a fixed list of TTRPG campaign characters
- `has_many :comments`
- No create/edit UI in this phase

### Comment
| Field | Type | Notes |
|-------|------|-------|
| edition_id | references | belongs_to Edition, required |
| character_id | references | belongs_to Character, required |
| body | text | required, max 500 chars |

- `Edition` gains `has_many :comments, dependent: :destroy`
- `Character` gains `has_many :comments`

## Routes

Comments are nested under editions (which are already nested under newspapers):

```ruby
resources :newspapers do
  resources :editions do
    resources :comments, only: [:create]
  end
end
```

## Architecture

### CommentsController
Single `create` action. On success responds with `format.turbo_stream`; falls back to redirect on plain HTML. No index, show, edit, or destroy actions in this phase.

### Broadcasting
One callback on the `Comment` model:

```ruby
after_create_commit -> {
  broadcast_append_to [edition, :comments],
    partial: "comments/comment",
    locals: { comment: self }
}
```

Uses Solid Cable (already configured). No new infrastructure required.

### Edition Show Page
Subscribes to the stream and renders the initial comment list below the front page grid:

```erb
<%= turbo_stream_from @edition, :comments %>
<div id="<%= dom_id(@edition, :comments) %>">
  <%= render @edition.comments %>
</div>
```

### Character Picker
The existing `SelectMenuComponent` is used as-is, styled with a dark/gold CSS wrapper class. Emojis in `<option>` tags (`🕵️ Constable Harrow`) render natively in modern browsers — no custom Alpine.js dropdown needed.

### Left/Right Bubble Personalization
The server renders all comment bubbles identically with a `data-character-id` attribute. A Stimulus `comment-thread` controller:

1. On `connect`, reads `characterId` from `localStorage`
2. Adds `.bubble--mine` to any bubble whose `data-character-id` matches
3. Watches for DOM mutations (new Turbo Stream appends) and applies the same check

`.bubble--mine` flips the bubble layout to the right side via `flex-direction: row-reverse`. The server has no concept of "current user" — personalization is entirely client-side.

The comment form's submit handler stores the selected `character_id` in `localStorage` so subsequent page loads and new bubbles stay personalized.

## Comment Thread UI

The comment section sits below the front page grid, separated by a horizontal rule. Three parts:

**Comment form:**
- Styled `SelectMenuComponent` for character selection (dark/gold, emoji + name)
- Textarea for message body
- "Post Comment" submit button
- On submit, stores `character_id` in `localStorage`

**Comment thread container:**
- `<div id="edition_N_comments">` — Turbo Stream append target
- Renders `comments/comment` partials

**`comments/comment` partial — each bubble contains:**
- Character emoji in a circular avatar
- Character name (small caps, above bubble)
- Message text
- Timestamp
- `data-character-id` attribute

**Visual style:** Dark ink background (`#1a1409`), gold border (`#c8a96e`), serif body text, Courier name label, directional tail on the bubble. Matches the newspaper's existing ink-and-parchment palette.

## Stimulus Controller

**`comment_thread_controller.js`** — attached to the thread container:
- Reads/writes `characterId` to `localStorage` key `zp_character_id`
- On connect: personalizes existing bubbles
- `MutationObserver` on the container: personalizes newly appended bubbles
- Exported `setCharacter(id)` method called by the form on submit

## Testing

### Model Tests
- `test/models/comment_test.rb`
  - Requires body, character, and edition
  - Rejects body over 500 characters
- `test/models/character_test.rb`
  - Requires name and emoji

### System Tests
- `test/system/comments_test.rb`
  - Posting a comment appends the bubble without a full page reload
  - New bubble shows the correct character name and message text
  - A second `visit` session on the same page receives the broadcast in real time (verifies Action Cable delivery end-to-end)
  - Submitting with an empty body shows a validation error

## Out of Scope

- Comment moderation, deletion, or editing
- Replies or threading
- Character create/edit UI
- Reaction counts or likes
- Comment counts on the edition index
