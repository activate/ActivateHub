class AddAdminToUsers < ActiveRecord::Migration
  def change
    add_column :users, :admin, :boolean, default: false

    # all pre-existing user were admins, so we're flagging them here
    User.all.each do |user|
      user.update_attributes(admin: true)
    end
  end
end
