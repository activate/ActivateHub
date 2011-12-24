class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.string :name
      t.timestamps
    end

    # Create join tables necessary for many-many relation.
    # See http://guides.rubyonrails.org/association_basics.html#creating-join-tables-for-has_and_belongs_to_many-associations

    create_table :events_topics, :id => false do |t|
      t.references :event
      t.references :topic
    end

    create_table :organizations_topics, :id => false do |t|
      t.references :organization
      t.references :topic
    end
  end

  def self.down
    drop_table :topics
    drop_table :events_topics
    drop_table :organizations_topics
  end
end
