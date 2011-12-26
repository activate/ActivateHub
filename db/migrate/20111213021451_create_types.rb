class CreateTypes < ActiveRecord::Migration
  def self.up
    create_table :types do |t|
      t.string :name

      t.timestamps
    end

    # Create join tables necessary for many-many relation.
    # See http://guides.rubyonrails.org/association_basics.html#creating-join-tables-for-has_and_belongs_to_many-associations

    create_table :events_types, :id => false do |t|
      t.references :event
      t.references :type
    end

    create_table :sources_types, :id => false do |t|
      t.references :source
      t.references :type
    end

  end

  def self.down
    drop_table :types
    drop_table :events_types
    drop_table :sources_types
  end
end
