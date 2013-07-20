class AddEnabledToSources < ActiveRecord::Migration
  def change
    add_column :sources, :enabled, :boolean, :default => true
  end
end
