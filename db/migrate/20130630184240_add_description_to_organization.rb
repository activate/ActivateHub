class AddDescriptionToOrganization < ActiveRecord::Migration
  def up
    add_column :organizations, :description, :string
  end

  def down
    remove_column :organizations, :description
  end
end
