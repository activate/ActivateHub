class AddGaAccountIdToSites < ActiveRecord::Migration
  def change
    add_column :sites, :ga_account_id, :string
  end
end
