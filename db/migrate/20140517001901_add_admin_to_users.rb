class AddAdminToUsers < ActiveRecord::Migration
  class User < ActiveRecord::Base ; end

  def change
    add_column :users, :admin, :boolean, default: false

    # all pre-existing users were admins, so we're flagging them here
    User.all.each do |user|
      user.update_attributes(admin: true)
    end
  end
end
