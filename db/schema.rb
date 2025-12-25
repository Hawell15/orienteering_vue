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

ActiveRecord::Schema[8.1].define(version: 2025_12_25_163019) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "category_name"
    t.datetime "created_at", null: false
    t.string "full_name"
    t.float "points"
    t.datetime "updated_at", null: false
    t.integer "validaty_period", default: 2
  end

  create_table "clubs", force: :cascade do |t|
    t.string "alternative_club_name"
    t.string "club_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "formatted_name"
    t.string "phone"
    t.string "representative"
    t.string "territory"
    t.datetime "updated_at", null: false
  end

  create_table "competitions", force: :cascade do |t|
    t.string "checksum"
    t.string "competition_name"
    t.string "country", default: "Moldova"
    t.datetime "created_at", null: false
    t.date "date"
    t.string "distance_type"
    t.boolean "ecn", default: false
    t.string "location"
    t.datetime "updated_at", null: false
    t.integer "wre_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "clasa"
    t.bigint "competition_id", default: 1, null: false
    t.datetime "created_at", null: false
    t.float "ecn_coeficient"
    t.string "group_name"
    t.integer "rang"
    t.datetime "updated_at", null: false
    t.index [ "competition_id" ], name: "index_groups_on_competition_id"
  end

  create_table "results", force: :cascade do |t|
    t.bigint "category_id", default: 10, null: false
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "ecn_points"
    t.bigint "group_id", default: 1, null: false
    t.integer "place"
    t.bigint "runner_id", null: false
    t.string "status"
    t.integer "time"
    t.datetime "updated_at", null: false
    t.integer "wre_points"
    t.index [ "category_id" ], name: "index_results_on_category_id"
    t.index [ "group_id" ], name: "index_results_on_group_id"
    t.index [ "runner_id" ], name: "index_results_on_runner_id"
  end

  create_table "runners", force: :cascade do |t|
    t.bigint "best_category_id", default: 10
    t.bigint "category_id", default: 10, null: false
    t.date "category_valid", default: "2100-01-01"
    t.string "checksum"
    t.bigint "club_id", default: 1, null: false
    t.datetime "created_at", null: false
    t.integer "forest_wre_place"
    t.integer "forest_wre_rang"
    t.string "gender"
    t.boolean "license", default: false
    t.string "runner_name"
    t.integer "sprint_wre_place"
    t.integer "sprint_wre_rang"
    t.string "surname"
    t.datetime "updated_at", null: false
    t.integer "wre_id"
    t.integer "yob", default: 2025
    t.index [ "best_category_id" ], name: "index_runners_on_best_category_id"
    t.index [ "category_id" ], name: "index_runners_on_category_id"
    t.index [ "club_id" ], name: "index_runners_on_club_id"
  end

  add_foreign_key "groups", "competitions"
  add_foreign_key "results", "categories"
  add_foreign_key "results", "groups"
  add_foreign_key "results", "runners"
  add_foreign_key "runners", "categories"
  add_foreign_key "runners", "clubs"
end
