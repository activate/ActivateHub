class AddOrganizationIdToSources < ActiveRecord::Migration
  def self.up
    add_column :sources, :organization_id, :integer
  end

  def self.down
    remove_column :sources, :organization_id
  end
end
