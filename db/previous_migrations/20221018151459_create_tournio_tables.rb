class CreateTournioTables < ActiveRecord::Migration[7.0]
  def change
    create_table "active_storage_attachments", if_not_exists: true do |t|
      t.string "name", null: false
      t.string "record_type", null: false
      t.bigint "record_id", null: false
      t.bigint "blob_id", null: false
      t.datetime "created_at", null: false
      t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
      t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
    end

    create_table "active_storage_blobs", if_not_exists: true do |t|
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

    create_table "active_storage_variant_records", if_not_exists: true do |t|
      t.bigint "blob_id", null: false
      t.string "variation_digest", null: false
      t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
    end

    create_table "additional_question_responses", if_not_exists: true do |t|
      t.bigint "bowler_id"
      t.bigint "extended_form_field_id"
      t.string "response", default: ""
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["bowler_id"], name: "index_additional_question_responses_on_bowler_id"
      t.index ["extended_form_field_id"], name: "index_additional_question_responses_on_extended_form_field_id"
    end

    create_table "additional_questions", if_not_exists: true do |t|
      t.bigint "tournament_id"
      t.bigint "extended_form_field_id"
      t.jsonb "validation_rules"
      t.integer "order"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["extended_form_field_id"], name: "index_additional_questions_on_extended_form_field_id"
      t.index ["tournament_id"], name: "index_additional_questions_on_tournament_id"
    end

    create_table "allowlisted_jwts", if_not_exists: true do |t|
      t.string "jti", null: false
      t.string "aud"
      t.datetime "exp", null: false
      t.bigint "user_id", null: false
      t.index ["jti"], name: "index_allowlisted_jwts_on_jti", unique: true
      t.index ["user_id"], name: "index_allowlisted_jwts_on_user_id"
    end

    create_table "bowlers", if_not_exists: true do |t|
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

    create_table "bowlers_shifts", if_not_exists: true do |t|
      t.bigint "bowler_id", null: false
      t.bigint "shift_id", null: false
      t.string "aasm_state", null: false
      t.datetime "confirmed_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["bowler_id"], name: "index_bowlers_shifts_on_bowler_id"
      t.index ["shift_id"], name: "index_bowlers_shifts_on_shift_id"
    end

    create_table "config_items", if_not_exists: true do |t|
      t.string "key", null: false
      t.string "value", null: false
      t.bigint "tournament_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tournament_id", "key"], name: "index_config_items_on_tournament_id_and_key", unique: true
    end

    create_table "contacts", if_not_exists: true do |t|
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

    create_table "data_points", if_not_exists: true do |t|
      t.integer "key", null: false
      t.string "value", null: false
      t.bigint "tournament_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["created_at"], name: "index_data_points_on_created_at"
      t.index ["key"], name: "index_data_points_on_key"
      t.index ["tournament_id"], name: "index_data_points_on_tournament_id"
    end

    create_table "events", if_not_exists: true do |t|
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

    create_table "events_scratch_divisions", id: false, if_not_exists: true do |t|
      t.bigint "event_id", null: false
      t.bigint "scratch_division_id", null: false
      t.index ["event_id", "scratch_division_id"], name: "event_division_idx", unique: true
    end

    create_table "extended_form_fields", if_not_exists: true do |t|
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

    create_table "external_payments", if_not_exists: true do |t|
      t.integer "payment_type", null: false
      t.string "identifier"
      t.jsonb "details"
      t.bigint "tournament_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["identifier"], name: "index_external_payments_on_identifier"
      t.index ["tournament_id"], name: "index_external_payments_on_tournament_id"
    end

    create_table "free_entries", if_not_exists: true do |t|
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

    create_table "ledger_entries", if_not_exists: true do |t|
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

    create_table "payment_summary_sends", if_not_exists: true do |t|
      t.bigint "tournament_id", null: false
      t.datetime "last_sent_at", precision: nil, null: false
      t.integer "bowler_count", default: 0
      t.index ["tournament_id"], name: "index_payment_summary_sends_on_tournament_id"
    end

    create_table "paypal_orders", if_not_exists: true do |t|
      t.string "identifier"
      t.jsonb "details"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "people", if_not_exists: true do |t|
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

    create_table "purchasable_items", if_not_exists: true do |t|
      t.string "identifier", null: false
      t.string "category", null: false
      t.string "determination", null: false
      t.string "refinement"
      t.string "name", null: false
      t.boolean "user_selectable", default: true, null: false
      t.integer "value", default: 0, null: false
      t.jsonb "configuration", default: {}
      t.bigint "tournament_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tournament_id"], name: "index_purchasable_items_on_tournament_id"
    end

    create_table "purchases", if_not_exists: true do |t|
      t.string "identifier", null: false
      t.bigint "bowler_id"
      t.bigint "purchasable_item_id"
      t.integer "amount", default: 0
      t.datetime "paid_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.bigint "external_payment_id"
      t.index ["bowler_id"], name: "index_purchases_on_bowler_id"
      t.index ["external_payment_id"], name: "index_purchases_on_external_payment_id"
      t.index ["identifier"], name: "index_purchases_on_identifier"
      t.index ["purchasable_item_id"], name: "index_purchases_on_purchasable_item_id"
    end

    create_table "registration_summary_sends", if_not_exists: true do |t|
      t.bigint "tournament_id", null: false
      t.datetime "last_sent_at", precision: nil, null: false
      t.integer "bowler_count", default: 0
      t.index ["tournament_id"], name: "index_registration_summary_sends_on_tournament_id"
    end

    create_table "scratch_divisions", if_not_exists: true do |t|
      t.bigint "tournament_id", null: false
      t.string "key", null: false
      t.string "name"
      t.integer "low_average", default: 0, null: false
      t.integer "high_average", default: 300, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tournament_id"], name: "index_scratch_divisions_on_tournament_id"
    end

    create_table "shifts", if_not_exists: true do |t|
      t.string "identifier", null: false
      t.string "name"
      t.string "description"
      t.jsonb "details", default: {"events"=>[], "registration_types"=>["new_team", "solo"]}
      t.integer "display_order", default: 1, null: false
      t.integer "capacity", default: 128, null: false
      t.integer "requested", default: 0, null: false
      t.integer "confirmed", default: 0, null: false
      t.bigint "tournament_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["identifier"], name: "index_shifts_on_identifier", unique: true
      t.index ["tournament_id"], name: "index_shifts_on_tournament_id"
    end

    create_table "stripe_accounts", primary_key: "identifier", id: :string, if_not_exists: true do |t|
      t.bigint "tournament_id", null: false
      t.datetime "onboarding_completed_at"
      t.string "link_url"
      t.datetime "link_expires_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tournament_id"], name: "index_stripe_accounts_on_tournament_id"
    end

    create_table "stripe_checkout_sessions", if_not_exists: true do |t|
      t.bigint "bowler_id", null: false
      t.string "identifier", null: false
      t.integer "status", default: 0
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["bowler_id"], name: "index_stripe_checkout_sessions_on_bowler_id"
      t.index ["identifier"], name: "index_stripe_checkout_sessions_on_identifier"
    end

    create_table "stripe_coupons", if_not_exists: true do |t|
      t.bigint "purchasable_item_id", null: false
      t.string "coupon_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["coupon_id"], name: "index_stripe_coupons_on_coupon_id"
      t.index ["purchasable_item_id"], name: "index_stripe_coupons_on_purchasable_item_id"
    end

    create_table "stripe_events", if_not_exists: true do |t|
      t.string "event_identifier"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["event_identifier"], name: "index_stripe_events_on_event_identifier"
    end

    create_table "stripe_products", if_not_exists: true do |t|
      t.bigint "purchasable_item_id", null: false
      t.string "product_id"
      t.string "price_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["product_id", "price_id"], name: "index_stripe_products_on_product_id_and_price_id"
      t.index ["purchasable_item_id"], name: "index_stripe_products_on_purchasable_item_id"
    end

    create_table "teams", if_not_exists: true do |t|
      t.bigint "tournament_id"
      t.string "identifier", null: false
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "options", default: {}
      t.index ["identifier"], name: "index_teams_on_identifier", unique: true
      t.index ["tournament_id"], name: "index_teams_on_tournament_id"
    end

    create_table "testing_environments", if_not_exists: true do |t|
      t.bigint "tournament_id", null: false
      t.jsonb "conditions", default: {"registration_period"=>"regular"}
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["tournament_id"], name: "index_testing_environments_on_tournament_id"
    end

    create_table "tournaments", if_not_exists: true do |t|
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
      t.index ["aasm_state"], name: "index_tournaments_on_aasm_state"
      t.index ["identifier"], name: "index_tournaments_on_identifier"
    end

    create_table "tournaments_users", id: false, if_not_exists: true do |t|
      t.bigint "tournament_id", null: false
      t.bigint "user_id", null: false
      t.index ["user_id", "tournament_id"], name: "index_tournaments_users_on_user_id_and_tournament_id", unique: true
    end

    create_table "users", if_not_exists: true do |t|
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

    add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id", if_not_exists: true
    add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id", if_not_exists: true
    add_foreign_key "allowlisted_jwts", "users", on_delete: :cascade, if_not_exists: true
    add_foreign_key "testing_environments", "tournaments", if_not_exists: true
  end
end
