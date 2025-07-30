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

ActiveRecord::Schema[8.0].define(version: 2025_07_30_092508) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "nas", id: :serial, force: :cascade do |t|
    t.text "nasname", null: false
    t.text "shortname", null: false
    t.text "type", default: "other", null: false
    t.integer "ports"
    t.text "secret", null: false
    t.text "server"
    t.text "community"
    t.text "description"
    t.index ["nasname"], name: "nas_nasname"
  end

  create_table "nasreload", primary_key: "nasipaddress", id: :inet, force: :cascade do |t|
    t.timestamptz "reloadtime", null: false
  end

  create_table "payment_callbacks", force: :cascade do |t|
    t.jsonb "data"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "payment_transactions", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.string "phone_number", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "client_mac", null: false
    t.string "client_ip", null: false
    t.string "link_login", null: false
    t.string "mpesa_checkout_request_id"
    t.string "mpesa_merchant_request_id"
    t.string "status", default: "pending", null: false
    t.jsonb "payment_details", default: {}
    t.string "username"
    t.string "password_digest"
    t.string "subscription_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "post_auth_status", default: "pending_auth", null: false
    t.datetime "authenticated_at"
    t.datetime "expected_stop_time"
    t.index ["expected_stop_time"], name: "index_payment_transactions_on_expected_stop_time"
    t.index ["mpesa_checkout_request_id"], name: "index_payment_transactions_on_mpesa_checkout_request_id", unique: true
    t.index ["post_auth_status"], name: "index_payment_transactions_on_post_auth_status"
    t.index ["subscription_id"], name: "index_payment_transactions_on_subscription_id"
  end

  create_table "radacct", primary_key: "radacctid", force: :cascade do |t|
    t.text "acctsessionid", null: false
    t.text "acctuniqueid", null: false
    t.text "username"
    t.text "realm"
    t.inet "nasipaddress", null: false
    t.text "nasportid"
    t.text "nasporttype"
    t.timestamptz "acctstarttime"
    t.timestamptz "acctupdatetime"
    t.timestamptz "acctstoptime"
    t.bigint "acctinterval"
    t.bigint "acctsessiontime"
    t.text "acctauthentic"
    t.text "connectinfo_start"
    t.text "connectinfo_stop"
    t.bigint "acctinputoctets"
    t.bigint "acctoutputoctets"
    t.text "calledstationid"
    t.text "callingstationid"
    t.text "acctterminatecause"
    t.text "servicetype"
    t.text "framedprotocol"
    t.inet "framedipaddress"
    t.inet "framedipv6address"
    t.inet "framedipv6prefix"
    t.text "framedinterfaceid"
    t.inet "delegatedipv6prefix"
    t.text "class"
    t.index ["acctstarttime", "username"], name: "radacct_start_user_idx"
    t.index ["acctuniqueid"], name: "radacct_active_session_idx", where: "(acctstoptime IS NULL)"
    t.index ["class"], name: "radacct_calss_idx"
    t.index ["nasipaddress", "acctstarttime"], name: "radacct_bulk_close", where: "(acctstoptime IS NULL)"
    t.unique_constraint ["acctuniqueid"], name: "radacct_acctuniqueid_key"
  end

  create_table "radcheck", id: :serial, force: :cascade do |t|
    t.text "username", default: "", null: false
    t.text "attribute", default: "", null: false
    t.string "op", limit: 2, default: "==", null: false
    t.text "value", default: "", null: false
    t.index ["username", "attribute"], name: "radcheck_username"
  end

  create_table "radgroupcheck", id: :serial, force: :cascade do |t|
    t.text "groupname", default: "", null: false
    t.text "attribute", default: "", null: false
    t.string "op", limit: 2, default: "==", null: false
    t.text "value", default: "", null: false
    t.index ["groupname", "attribute"], name: "radgroupcheck_groupname"
  end

  create_table "radgroupreply", id: :serial, force: :cascade do |t|
    t.text "groupname", default: "", null: false
    t.text "attribute", default: "", null: false
    t.string "op", limit: 2, default: "=", null: false
    t.text "value", default: "", null: false
    t.index ["groupname", "attribute"], name: "radgroupreply_groupname"
  end

  create_table "radpostauth", force: :cascade do |t|
    t.text "username", null: false
    t.text "pass"
    t.text "reply"
    t.text "calledstationid"
    t.text "callingstationid"
    t.timestamptz "authdate", default: -> { "now()" }, null: false
    t.text "class"
    t.index ["class"], name: "radpostauth_class_idx"
    t.index ["username"], name: "radpostauth_username_idx"
  end

  create_table "radreply", id: :serial, force: :cascade do |t|
    t.text "username", default: "", null: false
    t.text "attribute", default: "", null: false
    t.string "op", limit: 2, default: "=", null: false
    t.text "value", default: "", null: false
    t.index ["username", "attribute"], name: "radreply_username"
  end

  create_table "radusergroup", id: :serial, force: :cascade do |t|
    t.text "username", default: "", null: false
    t.text "groupname", default: "", null: false
    t.integer "priority", default: 0, null: false
    t.index ["username"], name: "radusergroup_username"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "duration_minutes", null: false
    t.string "freeradius_group_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["freeradius_group_name"], name: "index_subscriptions_on_freeradius_group_name"
    t.index ["name"], name: "index_subscriptions_on_name", unique: true
  end

  add_foreign_key "payment_transactions", "subscriptions"
end
