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

ActiveRecord::Schema[7.0].define(version: 2023_11_13_193935) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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

  create_table "additional_question_responses", force: :cascade do |t|
    t.bigint "bowler_id"
    t.bigint "extended_form_field_id"
    t.string "response", default: ""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bowler_id"], name: "index_additional_question_responses_on_bowler_id"
    t.index ["extended_form_field_id"], name: "index_additional_question_responses_on_extended_form_field_id"
  end

  create_table "additional_questions", force: :cascade do |t|
    t.bigint "tournament_id"
    t.bigint "extended_form_field_id"
    t.jsonb "validation_rules"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.index ["extended_form_field_id"], name: "index_additional_questions_on_extended_form_field_id"
    t.index ["tournament_id"], name: "index_additional_questions_on_tournament_id"
  end

  create_table "allowlisted_jwts", force: :cascade do |t|
    t.string "jti", null: false
    t.string "aud"
    t.datetime "exp", null: false
    t.bigint "user_id", null: false
    t.index ["jti"], name: "index_allowlisted_jwts_on_jti", unique: true
    t.index ["user_id"], name: "index_allowlisted_jwts_on_user_id"
  end

  create_table "bowlers", force: :cascade do |t|
    t.bigint "person_id"
    t.bigint "team_id"
    t.bigint "tournament_id"
    t.integer "position"
    t.bigint "doubles_partner_id"
    t.string "identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "verified_data", default: {}
    t.index ["created_at"], name: "index_bowlers_on_created_at"
    t.index ["doubles_partner_id"], name: "index_bowlers_on_doubles_partner_id"
    t.index ["identifier"], name: "index_bowlers_on_identifier"
    t.index ["person_id"], name: "index_bowlers_on_person_id"
    t.index ["team_id"], name: "index_bowlers_on_team_id"
    t.index ["tournament_id"], name: "index_bowlers_on_tournament_id"
  end

  create_table "config_items", force: :cascade do |t|
    t.string "key", null: false
    t.string "value", null: false
    t.bigint "tournament_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "label"
    t.index ["tournament_id", "key"], name: "index_config_items_on_tournament_id_and_key", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "tournament_id"
    t.string "name"
    t.string "email"
    t.string "phone"
    t.text "notes"
    t.boolean "notify_on_registration", default: false
    t.boolean "notify_on_payment", default: false
    t.integer "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notification_preference", default: 0
    t.string "identifier"
    t.index ["identifier"], name: "index_contacts_on_identifier", unique: true
    t.index ["tournament_id"], name: "index_contacts_on_tournament_id"
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "data_points", force: :cascade do |t|
    t.integer "key", null: false
    t.string "value", null: false
    t.bigint "tournament_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_data_points_on_created_at"
    t.index ["key"], name: "index_data_points_on_key"
    t.index ["tournament_id"], name: "index_data_points_on_tournament_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.integer "roster_type", null: false
    t.string "name", null: false
    t.boolean "required", default: true
    t.boolean "scratch", default: false
    t.boolean "permit_multiple_entries", default: false
    t.integer "game_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_events_on_tournament_id"
  end

  create_table "events_scratch_divisions", id: false, force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "scratch_division_id", null: false
    t.index ["event_id", "scratch_division_id"], name: "event_division_idx", unique: true
  end

  create_table "events_shifts", id: false, force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "shift_id", null: false
    t.index ["event_id"], name: "index_events_shifts_on_event_id"
    t.index ["shift_id"], name: "index_events_shifts_on_shift_id"
  end

  create_table "extended_form_fields", force: :cascade do |t|
    t.string "name", null: false
    t.string "label", null: false
    t.string "html_element_type", default: "input"
    t.jsonb "html_element_config", default: {"type"=>"text", "value"=>""}
    t.jsonb "validation_rules", default: {"required"=>false}
    t.string "helper_text"
    t.string "helper_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "external_payments", force: :cascade do |t|
    t.integer "payment_type", null: false
    t.string "identifier"
    t.jsonb "details"
    t.bigint "tournament_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_external_payments_on_identifier"
    t.index ["tournament_id"], name: "index_external_payments_on_tournament_id"
  end

  create_table "free_entries", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.string "unique_code"
    t.bigint "bowler_id"
    t.boolean "confirmed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.index ["bowler_id"], name: "index_free_entries_on_bowler_id"
    t.index ["identifier"], name: "index_free_entries_on_identifier", unique: true
    t.index ["tournament_id"], name: "index_free_entries_on_tournament_id"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "bowler_id", null: false
    t.decimal "debit", default: "0.0"
    t.decimal "credit", default: "0.0"
    t.integer "source", default: 0, null: false
    t.string "identifier"
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bowler_id"], name: "index_ledger_entries_on_bowler_id"
    t.index ["identifier"], name: "index_ledger_entries_on_identifier"
  end

  create_table "payment_summary_sends", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.datetime "last_sent_at", precision: nil, null: false
    t.integer "bowler_count", default: 0
    t.index ["tournament_id"], name: "index_payment_summary_sends_on_tournament_id"
  end

  create_table "paypal_orders", force: :cascade do |t|
    t.string "identifier"
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.integer "birth_month", null: false
    t.integer "birth_day", null: false
    t.string "nickname"
    t.string "address1", null: false
    t.string "address2"
    t.string "city", null: false
    t.string "state", null: false
    t.string "postal_code", null: false
    t.string "country", null: false
    t.string "phone", null: false
    t.string "igbo_id"
    t.string "usbc_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_name"], name: "index_people_on_last_name"
    t.index ["usbc_id"], name: "index_people_on_usbc_id"
  end

  create_table "purchasable_items", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "category", null: false
    t.string "determination"
    t.string "refinement"
    t.string "name", null: false
    t.boolean "user_selectable", default: true, null: false
    t.integer "value", default: 0, null: false
    t.jsonb "configuration", default: {}
    t.bigint "tournament_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "parent_id"
    t.boolean "enabled", default: true
    t.index ["tournament_id"], name: "index_purchasable_items_on_tournament_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.string "identifier", null: false
    t.bigint "bowler_id"
    t.bigint "purchasable_item_id"
    t.integer "amount", default: 0
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "external_payment_id"
    t.datetime "voided_at"
    t.string "void_reason"
    t.index ["bowler_id"], name: "index_purchases_on_bowler_id"
    t.index ["external_payment_id"], name: "index_purchases_on_external_payment_id"
    t.index ["identifier"], name: "index_purchases_on_identifier"
    t.index ["purchasable_item_id"], name: "index_purchases_on_purchasable_item_id"
  end

  create_table "registration_summary_sends", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.datetime "last_sent_at", precision: nil, null: false
    t.integer "bowler_count", default: 0
    t.index ["tournament_id"], name: "index_registration_summary_sends_on_tournament_id"
  end

  create_table "scratch_divisions", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.string "key", null: false
    t.string "name"
    t.integer "low_average", default: 0, null: false
    t.integer "high_average", default: 300, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_scratch_divisions_on_tournament_id"
  end

  create_table "send_grid_events", primary_key: "sg_event_id", id: :string, force: :cascade do |t|
    t.string "email"
    t.bigint "event_timestamp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shifts", force: :cascade do |t|
    t.string "identifier", null: false
    t.string "name"
    t.string "description"
    t.integer "display_order", default: 1, null: false
    t.integer "capacity", default: 128, null: false
    t.bigint "tournament_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_full", default: false
    t.string "event_string"
    t.string "group_title"
    t.index ["identifier"], name: "index_shifts_on_identifier", unique: true
    t.index ["tournament_id"], name: "index_shifts_on_tournament_id"
  end

  create_table "shifts_teams", id: false, force: :cascade do |t|
    t.bigint "shift_id", null: false
    t.bigint "team_id", null: false
    t.index ["shift_id"], name: "index_shifts_teams_on_shift_id"
    t.index ["team_id"], name: "index_shifts_teams_on_team_id"
  end

  create_table "stripe_accounts", primary_key: "identifier", id: :string, force: :cascade do |t|
    t.integer "tournament_id"
    t.datetime "onboarding_completed_at"
    t.string "link_url"
    t.datetime "link_expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "tournament_org_id"
    t.index ["tournament_id"], name: "index_stripe_accounts_on_tournament_id"
    t.index ["tournament_org_id"], name: "index_stripe_accounts_on_tournament_org_id"
  end

  create_table "stripe_checkout_sessions", force: :cascade do |t|
    t.bigint "bowler_id", null: false
    t.string "identifier", null: false
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bowler_id"], name: "index_stripe_checkout_sessions_on_bowler_id"
    t.index ["identifier"], name: "index_stripe_checkout_sessions_on_identifier"
  end

  create_table "stripe_coupons", force: :cascade do |t|
    t.bigint "purchasable_item_id", null: false
    t.string "coupon_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coupon_id"], name: "index_stripe_coupons_on_coupon_id"
    t.index ["purchasable_item_id"], name: "index_stripe_coupons_on_purchasable_item_id"
  end

  create_table "stripe_events", force: :cascade do |t|
    t.string "event_identifier"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_identifier"], name: "index_stripe_events_on_event_identifier"
  end

  create_table "stripe_products", force: :cascade do |t|
    t.bigint "purchasable_item_id", null: false
    t.string "product_id"
    t.string "price_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "price_id"], name: "index_stripe_products_on_product_id_and_price_id"
    t.index ["purchasable_item_id"], name: "index_stripe_products_on_purchasable_item_id"
  end

  create_table "teams", force: :cascade do |t|
    t.bigint "tournament_id"
    t.string "identifier", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "options", default: {}
    t.integer "initial_size", default: 4
    t.bigint "shift_id"
    t.index ["identifier"], name: "index_teams_on_identifier", unique: true
    t.index ["shift_id"], name: "index_teams_on_shift_id"
    t.index ["tournament_id"], name: "index_teams_on_tournament_id"
  end

  create_table "testing_environments", force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.jsonb "conditions", default: {"registration_period"=>"regular"}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_id"], name: "index_testing_environments_on_tournament_id"
  end

  create_table "tournament_orgs", force: :cascade do |t|
    t.string "name", null: false
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_tournament_orgs_on_identifier", unique: true
  end

  create_table "tournament_orgs_users", id: false, force: :cascade do |t|
    t.bigint "tournament_org_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tournament_org_id"], name: "index_tournament_orgs_users_on_tournament_org_id"
    t.index ["user_id"], name: "index_tournament_orgs_users_on_user_id"
  end

  create_table "tournaments", force: :cascade do |t|
    t.string "name", null: false
    t.integer "year", null: false
    t.string "identifier", null: false
    t.string "aasm_state", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.string "abbreviation"
    t.string "location"
    t.date "end_date"
    t.string "timezone", default: "America/New_York"
    t.datetime "entry_deadline"
    t.jsonb "details", default: {"enabled_registration_options"=>["new_team", "solo", "join_team"]}
    t.bigint "tournament_org_id"
    t.index ["aasm_state"], name: "index_tournaments_on_aasm_state"
    t.index ["identifier"], name: "index_tournaments_on_identifier"
    t.index ["tournament_org_id"], name: "index_tournaments_on_tournament_org_id"
  end

  create_table "tournaments_users", id: false, force: :cascade do |t|
    t.bigint "tournament_id", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "tournament_id"], name: "index_tournaments_users_on_user_id_and_tournament_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.integer "role", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["identifier"], name: "index_users_on_identifier", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "allowlisted_jwts", "users", on_delete: :cascade
  add_foreign_key "testing_environments", "tournaments"
end
