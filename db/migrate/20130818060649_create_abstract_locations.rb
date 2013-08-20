class CreateAbstractLocations < ActiveRecord::Migration
  def change
    create_table :abstract_locations do |t|
      t.references :site
      t.references :source
      t.references :venue

      t.string     :external_id
      t.string     :url
      t.string     :title
      t.text       :description

      t.string     :address
      t.string     :street_address
      t.string     :locality
      t.string     :region
      t.string     :postal_code
      t.string     :country

      t.decimal    :latitude,  :precision => 7, :scale => 4
      t.decimal    :longitude, :precision => 7, :scale => 4

      t.string     :email
      t.string     :telephone
      t.text       :tags

      t.string     :result
      t.text       :error_msg
      t.text       :raw_venue

      t.timestamps
    end

    add_index :abstract_locations, [:site_id, :source_id, :external_id], :name => 'index_abstract_locations_by_external_id'
    add_index :abstract_locations, :venue_id
  end
end
