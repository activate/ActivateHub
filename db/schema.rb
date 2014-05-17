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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140517001901) do

  create_table "abstract_events", :force => true do |t|
    t.integer  "site_id"
    t.integer  "source_id"
    t.integer  "event_id"
    t.string   "external_id"
    t.string   "url"
    t.string   "title"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "description"
    t.string   "venue_title"
    t.integer  "abstract_location_id"
    t.text     "tags"
    t.string   "result"
    t.text     "error_msg"
    t.text     "raw_event"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "abstract_events", ["event_id"], :name => "index_abstract_events_on_event_id"
  add_index "abstract_events", ["site_id", "source_id", "external_id"], :name => "abstract_events_by_external_id"
  add_index "abstract_events", ["site_id", "source_id", "start_time"], :name => "abstract_events_by_start_time"
  add_index "abstract_events", ["updated_at"], :name => "index_abstract_events_on_updated_at"

  create_table "abstract_locations", :force => true do |t|
    t.integer  "site_id"
    t.integer  "source_id"
    t.integer  "venue_id"
    t.string   "external_id"
    t.string   "url"
    t.string   "title"
    t.text     "description"
    t.string   "address"
    t.string   "street_address"
    t.string   "locality"
    t.string   "region"
    t.string   "postal_code"
    t.string   "country"
    t.decimal  "latitude",       :precision => 7, :scale => 4
    t.decimal  "longitude",      :precision => 7, :scale => 4
    t.string   "email"
    t.string   "telephone"
    t.text     "tags"
    t.string   "result"
    t.text     "error_msg"
    t.text     "raw_venue"
    t.datetime "created_at",                                   :null => false
    t.datetime "updated_at",                                   :null => false
  end

  add_index "abstract_locations", ["site_id", "source_id", "external_id"], :name => "index_abstract_locations_by_external_id"
  add_index "abstract_locations", ["updated_at"], :name => "index_abstract_locations_on_updated_at"
  add_index "abstract_locations", ["venue_id"], :name => "index_abstract_locations_on_venue_id"

  create_table "events", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "start_time"
    t.integer  "venue_id"
    t.string   "url"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "source_id"
    t.integer  "duplicate_of_id"
    t.datetime "end_time"
    t.string   "rrule"
    t.text     "venue_details"
    t.integer  "organization_id"
    t.integer  "site_id"
  end

  add_index "events", ["updated_at"], :name => "index_events_on_updated_at"

  create_table "events_topics", :id => false, :force => true do |t|
    t.integer "event_id"
    t.integer "topic_id"
  end

  add_index "events_topics", ["event_id"], :name => "index_events_topics_on_event_id"
  add_index "events_topics", ["topic_id"], :name => "index_events_topics_on_topic_id"

  create_table "events_types", :id => false, :force => true do |t|
    t.integer "event_id"
    t.integer "type_id"
  end

  add_index "events_types", ["event_id"], :name => "index_events_types_on_event_id"
  add_index "events_types", ["type_id"], :name => "index_events_types_on_type_id"

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "site_id"
    t.string   "contact_name"
    t.string   "email"
    t.string   "description"
  end

  add_index "organizations", ["updated_at"], :name => "index_organizations_on_updated_at"

  create_table "organizations_topics", :id => false, :force => true do |t|
    t.integer "organization_id"
    t.integer "topic_id"
  end

  add_index "organizations_topics", ["organization_id"], :name => "index_organizations_topics_on_organization_id"
  add_index "organizations_topics", ["topic_id"], :name => "index_organizations_topics_on_topic_id"

  create_table "rails_admin_histories", :force => true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      :limit => 2
    t.integer  "year",       :limit => 8
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], :name => "index_rails_admin_histories"

  create_table "sites", :force => true do |t|
    t.string   "name"
    t.string   "domain"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.string   "tagline"
    t.string   "timezone"
    t.float    "map_latitude"
    t.float    "map_longitude"
    t.integer  "map_zoom"
    t.string   "locale"
    t.string   "ga_account_id"
    t.string   "sharethis_key"
    t.string   "disqus_shortname"
  end

  add_index "sites", ["updated_at"], :name => "index_sites_on_updated_at"

  create_table "sources", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.datetime "imported_at"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "reimport"
    t.integer  "organization_id"
    t.integer  "site_id"
    t.boolean  "enabled",         :default => true
  end

  add_index "sources", ["updated_at"], :name => "index_sources_on_updated_at"

  create_table "sources_topics", :id => false, :force => true do |t|
    t.integer "source_id"
    t.integer "topic_id"
  end

  add_index "sources_topics", ["source_id"], :name => "index_sources_topics_on_source_id"
  add_index "sources_topics", ["topic_id"], :name => "index_sources_topics_on_topic_id"

  create_table "sources_types", :id => false, :force => true do |t|
    t.integer "source_id"
    t.integer "type_id"
  end

  add_index "sources_types", ["source_id"], :name => "index_sources_types_on_source_id"
  add_index "sources_types", ["type_id"], :name => "index_sources_types_on_type_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id",        :null => false
    t.integer  "taggable_id",   :null => false
    t.string   "taggable_type", :null => false
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "tags", ["name"], :name => "index_tags_on_name", :unique => true

  create_table "topics", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "site_id"
  end

  add_index "topics", ["site_id", "name"], :name => "index_topics_on_site_id_and_name"
  add_index "topics", ["updated_at"], :name => "index_topics_on_updated_at"

  create_table "types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "site_id"
  end

  add_index "types", ["site_id", "name"], :name => "index_types_on_site_id_and_name"
  add_index "types", ["updated_at"], :name => "index_types_on_updated_at"

  create_table "updates", :force => true do |t|
    t.integer  "source_id"
    t.text     "status"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                 :default => "",    :null => false
    t.string   "encrypted_password",     :limit => 128, :default => "",    :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.boolean  "admin",                                 :default => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  add_index "users", ["updated_at"], :name => "index_users_on_updated_at"

  create_table "venues", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.string   "address"
    t.string   "url"
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.string   "street_address"
    t.string   "locality"
    t.string   "region"
    t.string   "postal_code"
    t.string   "country"
    t.decimal  "latitude",        :precision => 7, :scale => 4
    t.decimal  "longitude",       :precision => 7, :scale => 4
    t.string   "email"
    t.string   "telephone"
    t.integer  "source_id"
    t.integer  "duplicate_of_id"
    t.boolean  "closed",                                        :default => false
    t.boolean  "wifi",                                          :default => false
    t.text     "access_notes"
    t.integer  "events_count"
    t.integer  "site_id"
  end

  add_index "venues", ["updated_at"], :name => "index_venues_on_updated_at"

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "site_id"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
