require 'spec_helper'

describe User do
  it "should be registerable" do
    user = create(:user)
    expect(user.devise_modules).to include :registerable
  end

  it "can be an admin" do
    user = create(:user)
    user.update_attributes(admin: true)

    expect(user.admin).to be_true
  end
end
