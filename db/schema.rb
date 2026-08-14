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

ActiveRecord::Schema[8.1].define(version: 2026_08_14_045131) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "end_date"
    t.date "start_date"
    t.text "title"
    t.datetime "updated_at", null: false
  end

  create_table "experiences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "features", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "hero_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "image"
    t.datetime "updated_at", null: false
  end

  create_table "local_activities", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "google_maps_url", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_local_activities_on_category"
    t.index ["position"], name: "index_local_activities_on_position"
  end

  create_table "offers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "price"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "page_contents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "key"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.string "badge"
    t.string "booking_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "features"
    t.string "name"
    t.integer "position"
    t.string "price"
    t.datetime "updated_at", null: false
  end

  create_table "themes", force: :cascade do |t|
    t.string "accent", null: false
    t.string "accent_soft", null: false
    t.boolean "active", default: false, null: false
    t.string "bg_primary", null: false
    t.string "bg_secondary", null: false
    t.string "bg_tertiary", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position"
    t.string "slug", null: false
    t.string "text_muted", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_themes_on_active"
    t.index ["slug"], name: "index_themes_on_slug", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.text "avo_preferences"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
