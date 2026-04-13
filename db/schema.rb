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

ActiveRecord::Schema[8.1].define(version: 2026_04_13_035039) do
  create_table "games", force: :cascade do |t|
    t.integer "away_team_id", null: false
    t.string "conference"
    t.datetime "created_at", null: false
    t.string "game_type"
    t.integer "home_team_id", null: false
    t.integer "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["away_team_id"], name: "index_games_on_away_team_id"
    t.index ["home_team_id"], name: "index_games_on_home_team_id"
    t.index ["tournament_id"], name: "index_games_on_tournament_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "abbreviation"
    t.string "conference"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "seed"
    t.integer "tournament_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_teams_on_tournament_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year"
    t.index ["year"], name: "index_tournaments_on_year", unique: true
  end

  create_table "user_picks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.integer "picked_winner_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id"], name: "index_user_picks_on_game_id"
    t.index ["picked_winner_id"], name: "index_user_picks_on_picked_winner_id"
    t.index ["user_id", "game_id"], name: "index_user_picks_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_user_picks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "games", "teams", column: "away_team_id"
  add_foreign_key "games", "teams", column: "home_team_id"
  add_foreign_key "games", "tournaments"
  add_foreign_key "sessions", "users"
  add_foreign_key "teams", "tournaments"
  add_foreign_key "user_picks", "games"
  add_foreign_key "user_picks", "teams", column: "picked_winner_id"
  add_foreign_key "user_picks", "users"
end
