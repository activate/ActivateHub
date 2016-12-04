class DropUpdates < ActiveRecord::Migration[5.0]
  def change
    drop_table :updates
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
