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

ActiveRecord::Schema[7.2].define(version: 2025_05_16_010355) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "cloudinary_uploads", force: :cascade do |t|
    t.string "name"
    t.string "public_id"
    t.string "resource_type"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "courses", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "latitude"
    t.decimal "longitude"
    t.integer "course_type"
    t.string "green_fee_range"
    t.integer "number_of_holes"
    t.integer "par"
    t.integer "yardage"
    t.string "website_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "course_tags", default: [], array: true
    t.string "notes"
    t.integer "green_fee"
    t.string "image_url"
    t.string "slug"
    t.string "google_place_id"
    t.json "summary"
    t.index ["course_tags"], name: "index_courses_on_course_tags", using: :gin
    t.index ["course_type"], name: "index_courses_on_course_type"
    t.index ["green_fee"], name: "index_courses_on_green_fee"
    t.index ["name"], name: "index_courses_on_name"
    t.index ["slug"], name: "index_courses_on_slug", unique: true
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "location_courses", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_location_courses_on_course_id"
    t.index ["location_id"], name: "index_location_courses_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "region"
    t.string "state"
    t.string "country"
    t.string "best_months"
    t.text "nearest_airports"
    t.text "weather_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reviews_count", default: 0, null: false
    t.integer "avg_green_fee"
    t.integer "avg_lodging_cost_per_night"
    t.integer "estimated_trip_cost"
    t.string "tags", default: [], array: true
    t.jsonb "summary"
    t.integer "lodging_price_min"
    t.integer "lodging_price_max"
    t.string "lodging_price_currency", default: "USD"
    t.datetime "lodging_price_last_updated"
    t.string "image_url"
    t.string "slug"
    t.index ["latitude", "longitude"], name: "index_locations_on_latitude_and_longitude"
    t.index ["name"], name: "index_locations_on_name"
    t.index ["region"], name: "index_locations_on_region"
    t.index ["slug"], name: "index_locations_on_slug", unique: true
    t.index ["state"], name: "index_locations_on_state"
    t.index ["tags"], name: "index_locations_on_tags", using: :gin
  end

  create_table "lodgings", force: :cascade do |t|
    t.string "google_place_id", null: false
    t.string "name", null: false
    t.string "types", default: [], array: true
    t.decimal "rating"
    t.decimal "latitude"
    t.decimal "longitude"
    t.string "formatted_address"
    t.string "formatted_phone_number"
    t.string "website"
    t.text "research_notes"
    t.string "research_status", default: "pending"
    t.date "research_last_attempted"
    t.integer "research_attempts", default: 0
    t.bigint "location_id", null: false
    t.boolean "is_featured", default: false
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_reference"
    t.index ["google_place_id"], name: "index_lodgings_on_google_place_id", unique: true
    t.index ["location_id"], name: "index_lodgings_on_location_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.integer "rating"
    t.date "played_on"
    t.string "course_condition"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_reviews_on_course_id"
    t.index ["user_id", "course_id", "played_on"], name: "index_reviews_on_user_id_and_course_id_and_played_on", unique: true
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "location_courses", "courses"
  add_foreign_key "location_courses", "locations"
  add_foreign_key "lodgings", "locations"
  add_foreign_key "reviews", "courses"
  add_foreign_key "reviews", "users"
end
