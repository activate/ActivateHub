class AddPathPrefixToSites < ActiveRecord::Migration
  def change
    add_column :sites, :path_prefix, :string
  end
end
