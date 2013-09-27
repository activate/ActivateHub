class AddLocaleToSites < ActiveRecord::Migration
  def up
    add_column :sites, :locale, :string

    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE sites SET locale = 'en-x-activate-hub';
    SQL
  end

  def down
    remove_column :sites, :locale
  end
end
