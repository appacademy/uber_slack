# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160723211211) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authorizations", force: :cascade do |t|
    t.string   "slack_user_id"
    t.string   "uber_auth_token"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "session_token"
    t.string   "uber_refresh_token"
    t.datetime "uber_access_token_expiration_time"
    t.string   "slack_response_url"
  end

  add_index "authorizations", ["uber_auth_token"], name: "index_authorizations_on_uber_auth_token", using: :btree

  create_table "rides", force: :cascade do |t|
    t.integer  "user_id",               null: false
    t.string   "surge_confirmation_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.float    "start_latitude"
    t.float    "start_longitude"
    t.float    "end_latitude"
    t.float    "end_longitude"
    t.string   "product_id"
    t.string   "request_id"
    t.float    "surge_multiplier"
    t.string   "origin_name"
    t.string   "destination_name"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                           null: false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.string   "password_digest"
    t.boolean  "admin",           default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree

end
