class RenameDefaultVenueToVenue < ActiveRecord::Migration
  def change
    rename_column :organizations, :default_venue_id, :venue_id
  end
end
