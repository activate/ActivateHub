class AddSettingsToSites < ActiveRecord::Migration
  def change
    add_column :sites, :tagline, :string
    add_column :sites, :timezone, :string
    add_column :sites, :map_latitude, :float
    add_column :sites, :map_longitude, :float
    add_column :sites, :map_zoom, :integer
  end
end
