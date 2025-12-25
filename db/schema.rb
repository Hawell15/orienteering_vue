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

ActiveRecord::Schema[8.0].define(version: 2025_12_25_161332) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "category_name"
    t.string "full_name"
    t.float "points"
    t.integer "validaty_period", default: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clubs", force: :cascade do |t|
    t.string "club_name"
    t.string "territory"
    t.string "representative"
    t.string "email"
    t.string "phone"
    t.string "alternative_club_name"
    t.string "formatted_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "competitions", force: :cascade do |t|
    t.string "competition_name"
    t.date "date"
    t.string "location"
    t.string "country", default: "Moldova"
    t.string "distance_type"
    t.integer "wre_id"
    t.string "checksum"
    t.boolean "ecn", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "runners", force: :cascade do |t|
    t.string "runner_name"
    t.string "surname"
    t.integer "yob", default: 2025
    t.string "gender"
    t.integer "wre_id"
    t.date "category_valid", default: "2100-01-01"
    t.integer "sprint_wre_rang"
    t.integer "forest_wre_rang"
    t.integer "sprint_wre_place"
    t.integer "forest_wre_place"
    t.string "checksum"
    t.boolean "license", default: false
    t.bigint "club_id", default: 1, null: false
    t.bigint "category_id", default: 10, null: false
    t.bigint "best_category_id", default: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "best_category_id" ], name: "index_runners_on_best_category_id"
    t.index [ "category_id" ], name: "index_runners_on_category_id"
    t.index [ "club_id" ], name: "index_runners_on_club_id"
  end

  add_foreign_key "runners", "categories"
  add_foreign_key "runners", "clubs"
end
