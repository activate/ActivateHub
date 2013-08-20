class CreateAbstractEvents < ActiveRecord::Migration
  def change
    create_table :abstract_events do |t|
      t.references :site
      t.references :source
      t.references :event

      t.string     :external_id
      t.string     :url
      t.string     :title
      t.datetime   :start_time
      t.datetime   :end_time
      t.text       :description

      t.string     :venue_title
      t.references :abstract_location

      t.text       :tags

      t.string     :result
      t.text       :error_msg
      t.text       :raw_event

      t.timestamps
    end

    add_index :abstract_events, [:site_id, :source_id, :start_time], :name => 'abstract_events_by_start_time'
    add_index :abstract_events, [:site_id, :source_id, :external_id], :name => 'abstract_events_by_external_id'
    add_index :abstract_events, :event_id
  end
end
