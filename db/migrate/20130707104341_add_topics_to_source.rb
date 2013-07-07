class AddTopicsToSource < ActiveRecord::Migration
  def up
    create_table :sources_topics, :id => false do |t|
      t.references :source
      t.references :topic
    end

    add_index :sources_topics, :source_id
    add_index :sources_topics, :topic_id

    Source.reset_column_information
    Source.scoped.each do |source|
      next unless source.organization

      source.topic_ids = source.organization.topic_ids
      source.save!
    end
  end

  def down
    drop_table :sources_topics, :id => false do |t|
      t.references :source
      t.references :topic
    end
  end
end
