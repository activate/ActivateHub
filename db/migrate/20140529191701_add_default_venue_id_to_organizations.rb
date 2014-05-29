class AddDefaultVenueIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :default_venue_id, :integer
  end
end
