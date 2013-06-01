class RemoveUsersAndRailsAdminTable < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.table_exists? 'users'
      drop_table 'users'
    end
    if ActiveRecord::Base.connection.table_exists? 'rails_admin_histories'
      drop_table 'rails_admin_histories'
    end
  end

  def down
  end
end
