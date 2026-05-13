# Comment Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a live-updating JRPG-style speech bubble comment section to each Edition page, where readers post as pre-seeded TTRPG characters with no accounts required.

**Architecture:** Comments belong to an Edition and a Character. The Comment model broadcasts new records via Action Cable (Solid Cable) using `broadcast_append_to`, which appends the new bubble to all subscribed browsers in real time. A Stimulus controller reads the selected character from `localStorage` and applies a `.bubble--mine` CSS class to flip matching bubbles to the right side — no server-side identity concept needed.

**Tech Stack:** Rails 8.1 / Minitest / Capybara / Selenium / Turbo Streams (turbo-rails) / Solid Cable / Stimulus / ViewComponent

---

## File Map

### New files
| File | Responsibility |
|------|----------------|
| `db/migrate/..._create_characters.rb` | Characters table (name, emoji) |
| `db/migrate/..._create_comments.rb` | Comments table (edition_id, character_id, body) |
| `app/models/character.rb` | Character model — validations, `has_many :comments` |
| `app/models/comment.rb` | Comment model — validations, `after_create_commit` broadcast |
| `app/controllers/comments_controller.rb` | `create` action only |
| `app/views/comments/_comment.html.erb` | Single comment bubble partial |
| `app/views/comments/create.turbo_stream.erb` | Clears body textarea + error div on success |
| `app/javascript/controllers/comment_thread_controller.js` | localStorage personalization + MutationObserver |
| `app/assets/stylesheets/components/comments.css` | Bubble layout, dark/gold palette, `.bubble--mine` flip |
| `test/models/character_test.rb` | Character validation tests |
| `test/models/comment_test.rb` | Comment validation tests |
| `test/system/comments_test.rb` | End-to-end: post comment, broadcast, validation error |
| `test/fixtures/characters.yml` | Test characters |
| `test/fixtures/comments.yml` | Test comments |

### Modified files
| File | Change |
|------|--------|
| `app/models/edition.rb` | Add `has_many :comments, dependent: :destroy` |
| `app/controllers/editions_controller.rb` | Load `@characters` in `show` and `show_current` |
| `config/routes.rb` | Nest `resources :comments, only: [:create]` under editions |
| `app/views/editions/show.html.erb` | Add comment section below `.newspaper-page` |
| `db/seeds.rb` | Seed TTRPG characters |
| `app/assets/stylesheets/application.css` | Import `components/comments.css` |

---

## Task 1: Character Model

**Files:**
- Create: `db/migrate/..._create_characters.rb` (via `rails generate migration`)
- Create: `app/models/character.rb`
- Modify: `db/seeds.rb`
- Create: `test/models/character_test.rb`
- Create: `test/fixtures/characters.yml`

- [ ] **Step 1: Write the failing tests**

Create `test/models/character_test.rb`:

```ruby
require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  test "valid with name and emoji" do
    character = Character.new(name: "Constable Harrow", emoji: "🕵️")
    assert character.valid?
  end

  test "invalid without name" do
    character = Character.new(emoji: "🕵️")
    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  test "invalid without emoji" do
    character = Character.new(name: "Constable Harrow")
    assert_not character.valid?
    assert_includes character.errors[:emoji], "can't be blank"
  end
end
```

- [ ] **Step 2: Add character fixtures**

Create `test/fixtures/characters.yml`:

```yaml
harrow:
  name: Constable Harrow
  emoji: "🕵️"

ysabette:
  name: Lady Ysabette
  emoji: "🧙"
```

- [ ] **Step 3: Run the tests — expect failure**

```bash
bin/rails test test/models/character_test.rb
```

Expected: errors about missing `Character` constant.

- [ ] **Step 4: Generate the migration**

```bash
bin/rails generate migration CreateCharacters name:string emoji:string
```

Open the generated file in `db/migrate/` and verify it looks like:

```ruby
class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.string :name, null: false
      t.string :emoji, null: false
      t.timestamps
    end
  end
end
```

Add `null: false` constraints if the generator omitted them.

- [ ] **Step 5: Run the migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 6: Create the model**

Create `app/models/character.rb`:

```ruby
class Character < ApplicationRecord
  has_many :comments, dependent: :nullify

  validates :name, :emoji, presence: true
end
```

- [ ] **Step 7: Run the tests — expect pass**

```bash
bin/rails test test/models/character_test.rb
```

Expected: 3 runs, 0 failures.

- [ ] **Step 8: Seed TTRPG characters**

Append to `db/seeds.rb`:

```ruby
[
  { name: "Constable Harrow",    emoji: "🕵️" },
  { name: "Lady Ysabette",       emoji: "🧙" },
  { name: "Engineer Volta",      emoji: "⚙️" },
  { name: "Captain Rutger",      emoji: "🗡️" },
  { name: "The Archivist",       emoji: "📜" },
  { name: "Bartholomew Pryce",   emoji: "🎩" }
].each { |attrs| Character.find_or_create_by!(name: attrs[:name]).update!(attrs) }
```

- [ ] **Step 9: Commit**

```bash
git add db/migrate db/schema.rb app/models/character.rb test/models/character_test.rb test/fixtures/characters.yml db/seeds.rb
git commit -m "feat(comments): add Character model"
```

---

## Task 2: Comment Model

**Files:**
- Create: `db/migrate/..._create_comments.rb` (via `rails generate migration`)
- Create: `app/models/comment.rb`
- Modify: `app/models/edition.rb`
- Create: `test/models/comment_test.rb`
- Create: `test/fixtures/comments.yml`

- [ ] **Step 1: Write the failing tests**

Create `test/models/comment_test.rb`:

```ruby
require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "valid with edition, character, and body" do
    comment = Comment.new(
      edition:   editions(:one),
      character: characters(:harrow),
      body:      "The Guild's silence speaks louder than any testimony."
    )
    assert comment.valid?
  end

  test "invalid without body" do
    comment = Comment.new(edition: editions(:one), character: characters(:harrow))
    assert_not comment.valid?
    assert_includes comment.errors[:body], "can't be blank"
  end

  test "invalid without edition" do
    comment = Comment.new(character: characters(:harrow), body: "Test.")
    assert_not comment.valid?
  end

  test "invalid without character" do
    comment = Comment.new(edition: editions(:one), body: "Test.")
    assert_not comment.valid?
  end

  test "invalid when body exceeds 500 characters" do
    comment = Comment.new(
      edition:   editions(:one),
      character: characters(:harrow),
      body:      "x" * 501
    )
    assert_not comment.valid?
    assert_includes comment.errors[:body], "is too long (maximum is 500 characters)"
  end

  test "valid when body is exactly 500 characters" do
    comment = Comment.new(
      edition:   editions(:one),
      character: characters(:harrow),
      body:      "x" * 500
    )
    assert comment.valid?
  end
end
```

- [ ] **Step 2: Add comment fixtures**

Create `test/fixtures/comments.yml`:

```yaml
one:
  edition: one
  character: harrow
  body: The Guild's silence speaks louder than any testimony.
```

- [ ] **Step 3: Run the tests — expect failure**

```bash
bin/rails test test/models/comment_test.rb
```

Expected: errors about missing `Comment` constant.

- [ ] **Step 4: Generate the migration**

```bash
bin/rails generate migration CreateComments edition:references character:references body:text
```

Open the generated file and verify it looks like:

```ruby
class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :edition,   null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
```

Add `null: false` to `body` if the generator omitted it.

- [ ] **Step 5: Run the migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 6: Create the Comment model**

Create `app/models/comment.rb`:

```ruby
class Comment < ApplicationRecord
  belongs_to :edition
  belongs_to :character

  validates :body, presence: true, length: { maximum: 500 }

  after_create_commit -> {
    broadcast_append_to [edition, :comments],
      target:  "edition_#{edition_id}_comments",
      partial: "comments/comment",
      locals:  { comment: self }
  }
end
```

- [ ] **Step 7: Add `has_many :comments` to Edition**

Edit `app/models/edition.rb` — add `has_many :comments, dependent: :destroy` after the `has_many :stories` line:

```ruby
class Edition < ApplicationRecord
  belongs_to :newspaper
  has_many :stories, dependent: :destroy
  has_many :comments, dependent: :destroy

  enum :season, { spring: 0, summer: 1, autumn: 2, winter: 3 }

  validates :year, :season, :day, :volume, :issue_number, presence: true
  validates :day, numericality: { in: 1..90 }

  def label
    "#{day.ordinalize} of #{season.capitalize}, #{year}"
  end
end
```

- [ ] **Step 8: Run the tests — expect pass**

```bash
bin/rails test test/models/comment_test.rb
```

Expected: 6 runs, 0 failures.

- [ ] **Step 9: Commit**

```bash
git add db/migrate db/schema.rb app/models/comment.rb app/models/edition.rb test/models/comment_test.rb test/fixtures/comments.yml
git commit -m "feat(comments): add Comment model with Action Cable broadcast"
```

---

## Task 3: Routes and CommentsController

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/comments_controller.rb`
- Create: `app/views/comments/create.turbo_stream.erb`

- [ ] **Step 1: Add nested route**

Edit `config/routes.rb`. Replace the editions block:

```ruby
resources :newspapers, only: [] do
  resources :editions, only: [:show] do
    resources :comments, only: [:create]
  end
end
```

- [ ] **Step 2: Verify the route was added**

```bash
bin/rails routes | grep comment
```

Expected output includes:

```
POST /newspapers/:newspaper_id/editions/:edition_id/comments  comments#create
```

- [ ] **Step 3: Create CommentsController**

Create `app/controllers/comments_controller.rb`:

```ruby
class CommentsController < ApplicationController
  before_action :set_edition

  def create
    @comment = @edition.comments.build(comment_params)
    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to newspaper_edition_path(@edition.newspaper, @edition) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("comment-errors",
            @comment.errors.full_messages.to_sentence),
            status: :unprocessable_entity
        end
        format.html { redirect_to newspaper_edition_path(@edition.newspaper, @edition) }
      end
    end
  end

  private

  def set_edition
    @edition = Edition.find(params[:edition_id])
  end

  def comment_params
    params.require(:comment).permit(:body, :character_id)
  end
end
```

- [ ] **Step 4: Create the Turbo Stream success response**

Create `app/views/comments/create.turbo_stream.erb`:

```erb
<%= turbo_stream.update "comment_body" do %><% end %>
<%= turbo_stream.update "comment-errors" do %><% end %>
```

This clears the body textarea and any error message after a successful post. The new bubble appears via Action Cable broadcast from the model — not from this response.

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb app/controllers/comments_controller.rb app/views/comments/create.turbo_stream.erb
git commit -m "feat(comments): add CommentsController and routes"
```

---

## Task 4: Comment Bubble Partial and CSS

**Files:**
- Create: `app/views/comments/_comment.html.erb`
- Create: `app/assets/stylesheets/components/comments.css`
- Modify: `app/assets/stylesheets/application.css`

- [ ] **Step 1: Create the comment partial**

Create `app/views/comments/_comment.html.erb`:

```erb
<div class="comment-bubble" data-character-id="<%= comment.character_id %>">
  <div class="comment-bubble__avatar">
    <%= comment.character.emoji %>
  </div>
  <div class="comment-bubble__body">
    <div class="comment-bubble__name"><%= comment.character.name %></div>
    <div class="comment-bubble__text"><%= comment.body %></div>
    <div class="comment-bubble__time"><%= time_ago_in_words(comment.created_at) %> ago</div>
  </div>
</div>
```

- [ ] **Step 2: Create the comments stylesheet**

Create `app/assets/stylesheets/components/comments.css`:

```css
/* ── Comment section wrapper ── */
.comment-section {
  max-width: 56rem;
  margin: var(--space-8) auto;
  padding: 0 var(--space-4);
  border-top: calc(var(--rule-width) * 3) double var(--color-rule);
  padding-top: var(--space-6);
}

.comment-section__heading {
  font-family: var(--font-headline);
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  color: var(--color-ink-muted);
  margin: 0 0 var(--space-6);
}

/* ── Comment thread ── */
.comment-thread {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  margin-bottom: var(--space-6);
}

/* ── Individual bubble ── */
.comment-bubble {
  display: flex;
  gap: var(--space-3);
  align-items: flex-end;
  max-width: 72%;
}

.bubble--mine {
  flex-direction: row-reverse;
  align-self: flex-end;
}

.comment-bubble__avatar {
  width: 2.5rem;
  height: 2.5rem;
  min-width: 2.5rem;
  border-radius: 50%;
  background: var(--color-ink);
  border: 2px solid var(--color-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.2rem;
}

.comment-bubble__body {
  display: flex;
  flex-direction: column;
  gap: 0.2rem;
}

.comment-bubble__name {
  font-family: var(--font-headline);
  font-size: 0.625rem;
  text-transform: uppercase;
  letter-spacing: 0.12em;
  color: var(--color-ink-muted);
}

.bubble--mine .comment-bubble__name {
  text-align: right;
}

.comment-bubble__text {
  background: var(--color-ink);
  color: var(--color-paper);
  border: 2px solid var(--color-accent);
  padding: var(--space-2) var(--space-3);
  font-family: var(--font-body);
  font-size: 0.9rem;
  line-height: 1.5;
  position: relative;
}

/* Left tail */
.comment-bubble__text::before {
  content: "";
  position: absolute;
  bottom: 0.6rem;
  left: -0.55rem;
  border: 0.28rem solid transparent;
  border-right-color: var(--color-accent);
}

/* Right tail for .bubble--mine */
.bubble--mine .comment-bubble__text::before {
  left: auto;
  right: -0.55rem;
  border-right-color: transparent;
  border-left-color: var(--color-accent);
}

.comment-bubble__time {
  font-size: 0.625rem;
  color: var(--color-ink-muted);
  font-family: var(--font-headline);
  letter-spacing: 0.05em;
}

.bubble--mine .comment-bubble__time {
  text-align: right;
}

/* ── Comment form ── */
.comment-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  border-top: var(--rule-width) solid var(--color-rule);
  padding-top: var(--space-4);
}

.comment-character-select {
  background: var(--color-ink);
  color: var(--color-paper);
  border: 2px solid var(--color-accent);
  font-family: var(--font-headline);
  font-size: 0.875rem;
  padding: var(--space-2) var(--space-3);
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6'%3E%3Cpath d='M0 0l5 6 5-6z' fill='%23c8a96e'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right var(--space-3) center;
  cursor: pointer;
  width: 100%;
  max-width: 22rem;
}

.comment-body-field {
  background: var(--color-ink);
  color: var(--color-paper);
  border: 2px solid var(--color-accent);
  font-family: var(--font-body);
  font-size: 0.9rem;
  padding: var(--space-2) var(--space-3);
  resize: vertical;
  min-height: 5rem;
  width: 100%;
  box-sizing: border-box;
  max-width: 44rem;
}

.comment-body-field::placeholder {
  color: var(--color-ink-muted);
  font-style: italic;
}

.comment-submit {
  background: var(--color-accent);
  color: var(--color-ink);
  border: none;
  font-family: var(--font-headline);
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.15em;
  padding: var(--space-2) var(--space-4);
  cursor: pointer;
  align-self: flex-start;
}

.comment-submit:hover {
  opacity: 0.85;
}

.comment-errors {
  font-family: var(--font-body);
  font-size: 0.875rem;
  color: #c0392b;
  font-style: italic;
  min-height: 1.25rem;
}

/* ── Mobile ── */
@media (max-width: 768px) {
  .comment-bubble {
    max-width: 90%;
  }

  .comment-character-select,
  .comment-body-field {
    max-width: 100%;
  }
}
```

- [ ] **Step 3: Import the stylesheet**

Edit `app/assets/stylesheets/application.css` — add the import after `story_overlay.css`:

```css
@import "components/story_overlay.css";
@import "components/comments.css";
@import "components/footer.css";
```

- [ ] **Step 4: Commit**

```bash
git add app/views/comments/_comment.html.erb app/assets/stylesheets/components/comments.css app/assets/stylesheets/application.css
git commit -m "feat(comments): add comment bubble partial and CSS"
```

---

## Task 5: Edition Show Page Integration

**Files:**
- Modify: `app/controllers/editions_controller.rb`
- Modify: `app/views/editions/show.html.erb`

- [ ] **Step 1: Load characters in EditionsController**

Edit `app/controllers/editions_controller.rb` to add `@characters = Character.order(:name)` to both `show` and `show_current`:

```ruby
class EditionsController < ApplicationController
  def show
    @edition = Edition.includes(:newspaper).find(params[:id])
    load_stories
    @characters = Character.order(:name)
  end

  def show_current
    @edition = Edition.includes(:newspaper).where(published: true).order(:id).first!
    load_stories
    @characters = Character.order(:name)
    render :show
  end

  private

  def load_stories
    non_ads  = @edition.stories.where.not(story_type: :advertisement).order(:story_type, :position)
    ads      = @edition.stories.advertisement.order(:position).limit(4)
    @stories = non_ads + ads
  end
end
```

- [ ] **Step 2: Add the comment section to the edition show view**

Edit `app/views/editions/show.html.erb` — insert the comment section between the `.newspaper-page` div and the `.overlay-frame` div:

```erb
<div class="newspaper-page">
  <%= render "masthead", edition: @edition %>

  <% articles, ads = @stories.partition { |s| !s.advertisement? } %>

  <div class="front-page-grid">
    <% articles.each do |story| %>
      <%= render StoryComponent.new(story: story) %>
    <% end %>
  </div>

  <% if ads.any? %>
    <div class="front-page-grid advertisements-grid">
      <% ads.each do |story| %>
        <%= render StoryComponent.new(story: story) %>
      <% end %>
    </div>
  <% end %>
</div>

<section class="comment-section" data-controller="comment-thread">
  <h2 class="comment-section__heading">Readers Respond</h2>

  <%= turbo_stream_from @edition, :comments %>

  <div id="edition_<%= @edition.id %>_comments" class="comment-thread">
    <%= render @edition.comments.includes(:character).order(:created_at) %>
  </div>

  <%= form_with model: [@edition.newspaper, @edition, Comment.new],
                id: "comment-form",
                class: "comment-form" do |f| %>
    <div id="comment-errors" class="comment-errors"></div>
    <%= render SelectMenuComponent.new(
      options:  @characters.map { |c| ["#{c.emoji} #{c.name}", c.id] },
      selected: "",
      name:     "comment[character_id]",
      data:     { action:                  "change->comment-thread#storeCharacter",
                  "comment-thread-target": "characterSelect" },
      class:    "comment-character-select"
    ) %>
    <%= f.text_area :body,
                    id:          "comment_body",
                    placeholder: "What do you make of this edition…",
                    class:       "comment-body-field" %>
    <%= f.submit "Post Comment", class: "comment-submit" %>
  <% end %>
</section>

<div class="overlay-frame"
     data-controller="overlay-frame"
     data-action="turbo:frame-load@window->overlay-frame#show click->overlay-frame#close">
  <turbo-frame id="story-overlay"
               class="overlay-frame__frame"
               data-overlay-frame-target="frame"
               data-action="click->overlay-frame#stopPropagation"></turbo-frame>
</div>
```

- [ ] **Step 3: Commit**

```bash
git add app/controllers/editions_controller.rb app/views/editions/show.html.erb
git commit -m "feat(comments): integrate comment section into edition show page"
```

---

## Task 6: Stimulus Comment Thread Controller

**Files:**
- Create: `app/javascript/controllers/comment_thread_controller.js`

The controller is auto-registered by `eagerLoadControllersFrom` in `controllers/index.js` — no changes to that file are needed.

- [ ] **Step 1: Create the Stimulus controller**

Create `app/javascript/controllers/comment_thread_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "zp_character_id"

export default class extends Controller {
  static targets = ["characterSelect"]

  connect() {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (stored && this.hasCharacterSelectTarget) {
      this.characterSelectTarget.value = stored
    }
    this.personalize()
    this.observer = new MutationObserver(() => this.personalize())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  storeCharacter(event) {
    localStorage.setItem(STORAGE_KEY, event.target.value)
    this.personalize()
  }

  personalize() {
    const id = localStorage.getItem(STORAGE_KEY)
    if (!id) return
    this.element.querySelectorAll("[data-character-id]").forEach(bubble => {
      bubble.classList.toggle("bubble--mine", bubble.dataset.characterId === id)
    })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/javascript/controllers/comment_thread_controller.js app/views/editions/show.html.erb
git commit -m "feat(comments): add comment-thread Stimulus controller for bubble personalization"
```

---

## Task 7: System Tests

**Files:**
- Create: `test/system/comments_test.rb`

- [ ] **Step 1: Write the system tests**

Create `test/system/comments_test.rb`:

```ruby
require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  setup do
    @edition   = editions(:one)
    @newspaper = @edition.newspaper
    visit newspaper_edition_path(@newspaper, @edition)
  end

  test "posting a comment appends it to the thread without a full page reload" do
    select "#{characters(:harrow).emoji} #{characters(:harrow).name}",
           from: "comment[character_id]"
    fill_in "comment[body]", with: "The Guild's silence speaks louder than any testimony."
    click_button "Post Comment"

    assert_selector ".comment-bubble .comment-bubble__name",
                    text: characters(:harrow).name, wait: 5
    assert_selector ".comment-bubble .comment-bubble__text",
                    text: "The Guild's silence speaks louder than any testimony."
  end

  test "body textarea is cleared after posting" do
    select "#{characters(:harrow).emoji} #{characters(:harrow).name}",
           from: "comment[character_id]"
    fill_in "comment[body]", with: "Test message."
    click_button "Post Comment"

    assert_selector ".comment-bubble", wait: 5
    assert_field "comment[body]", with: ""
  end

  test "submitting with an empty body shows a validation error" do
    select "#{characters(:harrow).emoji} #{characters(:harrow).name}",
           from: "comment[character_id]"
    click_button "Post Comment"

    assert_selector "#comment-errors", text: /can't be blank/i, wait: 5
    assert_no_selector ".comment-bubble .comment-bubble__text", text: ""
  end

  test "new comment is broadcast to a second browser session" do
    using_session(:viewer) do
      visit newspaper_edition_path(@newspaper, @edition)
    end

    using_session(:commenter) do
      visit newspaper_edition_path(@newspaper, @edition)
      select "#{characters(:ysabette).emoji} #{characters(:ysabette).name}",
             from: "comment[character_id]"
      fill_in "comment[body]", with: "I was there. This understates the danger."
      click_button "Post Comment"
    end

    using_session(:viewer) do
      assert_selector ".comment-bubble .comment-bubble__name",
                      text: characters(:ysabette).name, wait: 10
      assert_selector ".comment-bubble .comment-bubble__text",
                      text: "I was there. This understates the danger."
    end
  end
end
```

- [ ] **Step 2: Run the system tests**

```bash
bin/rails test test/system/comments_test.rb
```

Expected: 4 runs, 0 failures. (The broadcast test requires Action Cable to be running; the test suite uses `async` adapter in test env — confirm `config/cable.yml` uses `async` for test. If the broadcast test fails due to Action Cable not delivering in test mode, see the note below.)

> **Note on Action Cable in tests:** Rails test mode uses the `async` adapter by default (`config/cable.yml`). The `async` adapter delivers broadcasts in-process, so the two-session test should work without a real WebSocket server. If you see the broadcast test failing with a timeout, check that `config/cable.yml` has `adapter: async` for the test environment.

- [ ] **Step 3: Run the full test suite to check for regressions**

```bash
bin/rails test
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/system/comments_test.rb
git commit -m "test(comments): add system tests for comment section"
```
