class AddSharethisKeyToSites < ActiveRecord::Migration
  def change
    add_column :sites, :sharethis_key, :string
  end
end
