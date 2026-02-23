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

ActiveRecord::Schema[7.2].define(version: 2026_02_18_021900) do
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

  create_table "apps", force: :cascade do |t|
    t.string "name", null: false
    t.string "api_key_digest", null: false
    t.string "webhook_secret", null: false
    t.integer "status", default: 0, null: false
    t.string "timezone", default: "UTC", null: false
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_key_digest"], name: "index_apps_on_api_key_digest", unique: true
    t.index ["name"], name: "index_apps_on_name", unique: true
    t.index ["status"], name: "index_apps_on_status"
  end

  create_table "cashout_requests", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "amount_cents", null: false
    t.integer "status", default: 0, null: false
    t.string "payout_method"
    t.string "payout_reference"
    t.bigint "reviewed_by_admin_user_id"
    t.datetime "reviewed_at"
    t.datetime "paid_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewed_by_admin_user_id"], name: "index_cashout_requests_on_reviewed_by_admin_user_id"
    t.index ["status", "created_at"], name: "index_cashout_requests_on_status_and_created_at"
    t.index ["user_id", "status", "created_at"], name: "index_cashout_requests_on_user_id_and_status_and_created_at"
    t.index ["user_id"], name: "index_cashout_requests_on_user_id"
  end

  create_table "idempotency_keys", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.string "key", null: false
    t.string "request_hash", null: false
    t.integer "response_code"
    t.jsonb "response_body", default: {}, null: false
    t.datetime "first_seen_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "key"], name: "index_idempotency_keys_on_app_id_and_key", unique: true
    t.index ["app_id"], name: "index_idempotency_keys_on_app_id"
    t.index ["expires_at"], name: "index_idempotency_keys_on_expires_at"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.bigint "user_id", null: false
    t.integer "entry_type", null: false
    t.integer "account_type", null: false
    t.bigint "amount_cents", null: false
    t.string "reference_type"
    t.bigint "reference_id"
    t.datetime "occurred_at", null: false
    t.string "created_by_type"
    t.bigint "created_by_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "occurred_at"], name: "index_ledger_entries_on_app_id_and_occurred_at"
    t.index ["app_id"], name: "index_ledger_entries_on_app_id"
    t.index ["reference_type", "reference_id"], name: "index_ledger_entries_on_reference_type_and_reference_id"
    t.index ["user_id", "occurred_at"], name: "index_ledger_entries_on_user_id_and_occurred_at"
    t.index ["user_id"], name: "index_ledger_entries_on_user_id"
  end

  create_table "referral_codes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "code", null: false
    t.boolean "active", default: true, null: false
    t.integer "format_version", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_referral_codes_on_code", unique: true
    t.index ["user_id", "active"], name: "index_referral_codes_on_user_id_and_active", unique: true, where: "(active = true)"
    t.index ["user_id"], name: "index_referral_codes_on_user_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.bigint "referrer_user_id", null: false
    t.bigint "referral_code_id", null: false
    t.string "external_user_id", null: false
    t.datetime "referred_at", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "external_user_id"], name: "index_referrals_on_app_id_and_external_user_id", unique: true
    t.index ["app_id", "referrer_user_id"], name: "index_referrals_on_app_id_and_referrer_user_id"
    t.index ["app_id"], name: "index_referrals_on_app_id"
    t.index ["referral_code_id"], name: "index_referrals_on_referral_code_id"
    t.index ["referrer_user_id"], name: "index_referrals_on_referrer_user_id"
    t.index ["status"], name: "index_referrals_on_status"
  end

  create_table "reward_rules", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.integer "event_type", null: false
    t.integer "reward_mode", default: 0, null: false
    t.bigint "amount_cents"
    t.integer "percentage_bps"
    t.integer "recurrence_mode", default: 0, null: false
    t.integer "pending_days", default: 0, null: false
    t.datetime "active_from"
    t.datetime "active_to"
    t.boolean "enabled", default: true, null: false
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "event_type", "enabled"], name: "index_reward_rules_on_app_id_and_event_type_and_enabled"
    t.index ["app_id"], name: "index_reward_rules_on_app_id"
  end

  create_table "reward_transactions", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.bigint "referral_id", null: false
    t.bigint "user_id", null: false
    t.bigint "source_event_id"
    t.integer "event_type", null: false
    t.string "external_transaction_id"
    t.string "idempotency_fingerprint", null: false
    t.bigint "gross_cents", default: 0, null: false
    t.bigint "reward_cents", null: false
    t.integer "status", default: 0, null: false
    t.datetime "available_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "event_type", "external_transaction_id"], name: "idx_reward_txns_unique_external_event_per_app", unique: true, where: "(external_transaction_id IS NOT NULL)"
    t.index ["app_id"], name: "index_reward_transactions_on_app_id"
    t.index ["idempotency_fingerprint"], name: "index_reward_transactions_on_idempotency_fingerprint", unique: true
    t.index ["referral_id"], name: "index_reward_transactions_on_referral_id"
    t.index ["source_event_id"], name: "index_reward_transactions_on_source_event_id"
    t.index ["user_id", "status", "available_at"], name: "idx_on_user_id_status_available_at_6bc287cb5c"
    t.index ["user_id"], name: "index_reward_transactions_on_user_id"
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
    t.integer "status", default: 0, null: false
    t.bigint "available_cents", default: 0, null: false
    t.bigint "pending_cents", default: 0, null: false
    t.bigint "total_earned_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "webhook_events", force: :cascade do |t|
    t.bigint "app_id", null: false
    t.integer "event_type", null: false
    t.string "idempotency_key_raw", null: false
    t.string "request_signature", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "received_at", null: false
    t.integer "status", default: 0, null: false
    t.string "error_code"
    t.text "error_message"
    t.datetime "processed_at"
    t.integer "attempt_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id", "idempotency_key_raw"], name: "index_webhook_events_on_app_id_and_idempotency_key_raw", unique: true
    t.index ["app_id", "received_at"], name: "index_webhook_events_on_app_id_and_received_at"
    t.index ["app_id"], name: "index_webhook_events_on_app_id"
    t.index ["status", "received_at"], name: "index_webhook_events_on_status_and_received_at"
  end

  add_foreign_key "cashout_requests", "admin_users", column: "reviewed_by_admin_user_id"
  add_foreign_key "cashout_requests", "users"
  add_foreign_key "idempotency_keys", "apps"
  add_foreign_key "ledger_entries", "apps"
  add_foreign_key "ledger_entries", "users"
  add_foreign_key "referral_codes", "users"
  add_foreign_key "referrals", "apps"
  add_foreign_key "referrals", "referral_codes"
  add_foreign_key "referrals", "users", column: "referrer_user_id"
  add_foreign_key "reward_rules", "apps"
  add_foreign_key "reward_transactions", "apps"
  add_foreign_key "reward_transactions", "referrals"
  add_foreign_key "reward_transactions", "users"
  add_foreign_key "reward_transactions", "webhook_events", column: "source_event_id"
  add_foreign_key "webhook_events", "apps"
end
