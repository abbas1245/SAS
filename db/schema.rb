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

ActiveRecord::Schema[8.0].define(version: 2025_05_22_082002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.date "date", null: false
    t.string "status", null: false
    t.text "notes"
    t.bigint "student_id", null: false
    t.bigint "teacher_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "class_standard"
    t.index ["class_standard"], name: "index_attendances_on_class_standard"
    t.index ["student_id"], name: "index_attendances_on_student_id"
    t.index ["teacher_id"], name: "index_attendances_on_teacher_id"
  end

  create_table "class_standards", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "code", null: false
    t.integer "year", null: false
    t.string "section"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_class_standards_on_code", unique: true
    t.index ["year", "section"], name: "index_class_standards_on_year_and_section", unique: true
  end

  create_table "teacher_class_standards", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "class_standard_id", null: false
    t.boolean "is_primary_teacher", default: false
    t.date "start_date", null: false
    t.date "end_date"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["class_standard_id"], name: "index_teacher_class_standards_on_class_standard_id"
    t.index ["teacher_id", "class_standard_id"], name: "index_teacher_class_standards_unique", unique: true
    t.index ["teacher_id"], name: "index_teacher_class_standards_on_teacher_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.json "dashboard_settings", default: {"show_attendance_stats" => true, "show_recent_activities" => true, "show_quick_actions" => true, "default_view" => "overview", "notification_preferences" => {"email" => true, "dashboard" => true}}
    t.string "first_name"
    t.string "last_name"
    t.string "class_standard"
    t.boolean "active", default: true, null: false
    t.string "roll_number"
    t.index ["class_standard"], name: "index_users_on_class_standard"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["roll_number"], name: "index_users_on_roll_number", unique: true
    t.check_constraint "role = 0 OR role = 1 AND first_name IS NOT NULL AND last_name IS NOT NULL OR role = 2 AND class_standard IS NOT NULL AND first_name IS NOT NULL AND last_name IS NOT NULL", name: "check_user_fields"
  end

  add_foreign_key "attendances", "users", column: "student_id"
  add_foreign_key "attendances", "users", column: "teacher_id"
  add_foreign_key "teacher_class_standards", "class_standards"
  add_foreign_key "teacher_class_standards", "users", column: "teacher_id"
end
