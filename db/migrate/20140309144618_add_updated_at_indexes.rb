class AddUpdatedAtIndexes < ActiveRecord::Migration
  def change
#   add_timestamps :events_topics
#   add_timestamps :events_types
#   add_timestamps :organizations_topics
#   add_timestamps :sources_topics
#   add_timestamps :sources_types

    add_index :abstract_events,      :updated_at
    add_index :abstract_locations,   :updated_at
    add_index :events,               :updated_at
    add_index :organizations,        :updated_at
    add_index :sites,                :updated_at
    add_index :sources,              :updated_at
    add_index :topics,               :updated_at
    add_index :types,                :updated_at
    add_index :users,                :updated_at
    add_index :venues,               :updated_at
  end
end
