class AddDisqusShortnameToSites < ActiveRecord::Migration
  def change
    add_column :sites, :disqus_shortname, :string
  end
end
