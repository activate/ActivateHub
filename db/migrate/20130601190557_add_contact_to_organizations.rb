class AddContactToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :contact_name, :string
    add_column :organizations, :email, :string
  end
end
