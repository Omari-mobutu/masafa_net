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

ActiveRecord::Schema[8.0].define(version: 0) do
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
end
