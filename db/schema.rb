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

ActiveRecord::Schema.define(version: 20170129122904) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "abstract_events", force: :cascade do |t|
    t.integer  "site_id"
    t.integer  "source_id"
    t.integer  "event_id"
    t.string   "external_id",          limit: 255
    t.string   "url",                  limit: 255
    t.string   "title",                limit: 255
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "description"
    t.string   "venue_title",          limit: 255
    t.integer  "abstract_location_id"
    t.text     "tags"
    t.string   "result",               limit: 255
    t.text     "error_msg"
    t.text     "raw_event"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.index ["event_id"], name: "index_abstract_events_on_event_id", using: :btree
    t.index ["site_id", "source_id", "external_id"], name: "abstract_events_by_external_id", using: :btree
    t.index ["site_id", "source_id", "start_time"], name: "abstract_events_by_start_time", using: :btree
    t.index ["updated_at"], name: "index_abstract_events_on_updated_at", using: :btree
  end

  create_table "abstract_locations", force: :cascade do |t|
    t.integer  "site_id"
    t.integer  "source_id"
    t.integer  "venue_id"
    t.string   "external_id",    limit: 255
    t.string   "url",            limit: 255
    t.string   "title",          limit: 255
    t.text     "description"
    t.string   "address",        limit: 255
    t.string   "street_address", limit: 255
    t.string   "locality",       limit: 255
    t.string   "region",         limit: 255
    t.string   "postal_code",    limit: 255
    t.string   "country",        limit: 255
    t.decimal  "latitude",                   precision: 7, scale: 4
    t.decimal  "longitude",                  precision: 7, scale: 4
    t.string   "email",          limit: 255
    t.string   "telephone",      limit: 255
    t.text     "tags"
    t.string   "result",         limit: 255
    t.text     "error_msg"
    t.text     "raw_venue"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.index ["site_id", "source_id", "external_id"], name: "index_abstract_locations_by_external_id", using: :btree
    t.index ["updated_at"], name: "index_abstract_locations_on_updated_at", using: :btree
    t.index ["venue_id"], name: "index_abstract_locations_on_venue_id", using: :btree
  end

  create_table "events", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.text     "description"
    t.datetime "start_time"
    t.integer  "venue_id"
    t.string   "url",             limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "source_id"
    t.integer  "duplicate_of_id"
    t.datetime "end_time"
    t.string   "rrule",           limit: 255
    t.text     "venue_details"
    t.integer  "organization_id"
    t.integer  "site_id"
    t.index ["updated_at"], name: "index_events_on_updated_at", using: :btree
  end

  create_table "events_topics", id: false, force: :cascade do |t|
    t.integer "event_id"
    t.integer "topic_id"
    t.index ["event_id"], name: "index_events_topics_on_event_id", using: :btree
    t.index ["topic_id"], name: "index_events_topics_on_topic_id", using: :btree
  end

  create_table "events_types", id: false, force: :cascade do |t|
    t.integer "event_id"
    t.integer "type_id"
    t.index ["event_id"], name: "index_events_types_on_event_id", using: :btree
    t.index ["type_id"], name: "index_events_types_on_type_id", using: :btree
  end

  create_table "organizations", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "url",          limit: 255
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "site_id"
    t.string   "contact_name", limit: 255
    t.string   "email",        limit: 255
    t.string   "description",  limit: 255
    t.integer  "venue_id"
    t.index ["updated_at"], name: "index_organizations_on_updated_at", using: :btree
  end

  create_table "organizations_topics", id: false, force: :cascade do |t|
    t.integer "organization_id"
    t.integer "topic_id"
    t.index ["organization_id"], name: "index_organizations_topics_on_organization_id", using: :btree
    t.index ["topic_id"], name: "index_organizations_topics_on_topic_id", using: :btree
  end

  create_table "rails_admin_histories", force: :cascade do |t|
    t.text     "message"
    t.string   "username",   limit: 255
    t.integer  "item"
    t.string   "table",      limit: 255
    t.integer  "month",      limit: 2
    t.bigint   "year"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["item", "table", "month", "year"], name: "index_rails_admin_histories", using: :btree
  end

  create_table "site_domains", force: :cascade do |t|
    t.integer  "site_id",                   null: false
    t.string   "domain",                    null: false
    t.boolean  "redirect",   default: true, null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["domain"], name: "index_site_domains_on_domain", unique: true, using: :btree
    t.index ["site_id"], name: "index_site_domains_on_site_id", using: :btree
  end

  create_table "sites", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.string   "domain",           limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "tagline",          limit: 255
    t.string   "timezone",         limit: 255
    t.float    "map_latitude"
    t.float    "map_longitude"
    t.integer  "map_zoom"
    t.string   "locale",           limit: 255
    t.string   "ga_account_id",    limit: 255
    t.string   "sharethis_key",    limit: 255
    t.string   "disqus_shortname", limit: 255
    t.index ["updated_at"], name: "index_sites_on_updated_at", using: :btree
  end

  create_table "sources", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.string   "url",             limit: 255
    t.datetime "imported_at"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "reimport"
    t.integer  "organization_id"
    t.integer  "site_id"
    t.boolean  "enabled",                     default: true
    t.index ["updated_at"], name: "index_sources_on_updated_at", using: :btree
  end

  create_table "sources_topics", id: false, force: :cascade do |t|
    t.integer "source_id"
    t.integer "topic_id"
    t.index ["source_id"], name: "index_sources_topics_on_source_id", using: :btree
    t.index ["topic_id"], name: "index_sources_topics_on_topic_id", using: :btree
  end

  create_table "sources_types", id: false, force: :cascade do |t|
    t.integer "source_id"
    t.integer "type_id"
    t.index ["source_id"], name: "index_sources_types_on_source_id", using: :btree
    t.index ["type_id"], name: "index_sources_types_on_type_id", using: :btree
  end

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id",                    null: false
    t.integer  "taggable_id",               null: false
    t.string   "taggable_type", limit: 255, null: false
    t.integer  "tagger_id"
    t.string   "tagger_type",   limit: 255
    t.string   "context",       limit: 255
    t.datetime "created_at"
    t.index ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
  end

  create_table "tags", force: :cascade do |t|
    t.string  "name",           limit: 255,             null: false
    t.integer "taggings_count",             default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true, using: :btree
  end

  create_table "topics", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "site_id"
    t.boolean  "enabled",                default: true
    t.index ["site_id", "name"], name: "index_topics_on_site_id_and_name", using: :btree
    t.index ["updated_at"], name: "index_topics_on_updated_at", using: :btree
  end

  create_table "types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.integer  "site_id"
    t.boolean  "enabled",                default: true
    t.index ["site_id", "name"], name: "index_types_on_site_id_and_name", using: :btree
    t.index ["updated_at"], name: "index_types_on_updated_at", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 128, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "admin",                              default: false
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["updated_at"], name: "index_users_on_updated_at", using: :btree
  end

  create_table "venues", force: :cascade do |t|
    t.string   "title",           limit: 255
    t.text     "description"
    t.string   "address",         limit: 255
    t.string   "url",             limit: 255
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.string   "street_address",  limit: 255
    t.string   "locality",        limit: 255
    t.string   "region",          limit: 255
    t.string   "postal_code",     limit: 255
    t.string   "country",         limit: 255
    t.decimal  "latitude",                    precision: 7, scale: 4
    t.decimal  "longitude",                   precision: 7, scale: 4
    t.string   "email",           limit: 255
    t.string   "telephone",       limit: 255
    t.integer  "source_id"
    t.integer  "duplicate_of_id"
    t.boolean  "closed",                                              default: false
    t.boolean  "wifi",                                                default: false
    t.text     "access_notes"
    t.integer  "events_count"
    t.integer  "site_id"
    t.text     "geo_precision"
    t.index ["updated_at"], name: "index_venues_on_updated_at", using: :btree
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255, null: false
    t.integer  "item_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object"
    t.datetime "created_at"
    t.integer  "site_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  end

  add_foreign_key "site_domains", "sites"
end
