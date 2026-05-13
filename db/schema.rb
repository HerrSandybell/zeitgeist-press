# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_13_190423) do
  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "editions", force: :cascade do |t|
    t.string "attention_bar"
    t.string "city"
    t.datetime "created_at", null: false
    t.integer "day"
    t.string "edition_type"
    t.integer "issue_number"
    t.integer "newspaper_id", null: false
    t.string "price"
    t.boolean "published", default: false, null: false
    t.integer "season"
    t.datetime "updated_at", null: false
    t.integer "volume"
    t.integer "year"
    t.index ["newspaper_id"], name: "index_editions_on_newspaper_id"
  end

  create_table "newspapers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "print_location"
    t.string "tagline"
    t.datetime "updated_at", null: false
  end

  create_table "stories", force: :cascade do |t|
    t.string "author"
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "edition_id"
    t.string "headline"
    t.integer "position"
    t.text "quote"
    t.string "quote_origin"
    t.integer "story_type"
    t.string "subtitle"
    t.string "summary_ticker"
    t.string "supertitle"
    t.datetime "updated_at", null: false
    t.index ["edition_id"], name: "index_stories_on_edition_id"
  end

  add_foreign_key "editions", "newspapers"
  add_foreign_key "stories", "editions"
end
