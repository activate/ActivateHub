class AddEnabledToTopicsTypes < ActiveRecord::Migration[5.0]
  def change
    add_column :topics, :enabled, :boolean, :default => true
    add_column :types, :enabled, :boolean, :default => true
  end
end
