class AddIndexesToTopicsTypes < ActiveRecord::Migration
  def change
    add_index :topics, [:site_id, :name]
    add_index :types, [:site_id, :name]

    add_index :events_topics, :event_id
    add_index :events_topics, :topic_id
    add_index :events_types, :event_id
    add_index :events_types, :type_id

    add_index :organizations_topics, :organization_id
    add_index :organizations_topics, :topic_id

    add_index :sources_types, :source_id
    add_index :sources_types, :type_id
  end
end
