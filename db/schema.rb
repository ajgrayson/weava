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

ActiveRecord::Schema.define(version: 20131110015405) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "project_shares", force: true do |t|
    t.integer  "project_id"
    t.integer  "owner_id"
    t.integer  "user_id"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "accepted"
  end

  create_table "projects", force: true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.boolean  "owner"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "conflict"
    t.string   "project_type"
  end

  create_table "projects_users", id: false, force: true do |t|
    t.integer "project_id", null: false
    t.integer "user_id",    null: false
    t.integer "role"
  end

  add_index "projects_users", ["project_id", "user_id"], name: "index_projects_users_on_project_id_and_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "session_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
