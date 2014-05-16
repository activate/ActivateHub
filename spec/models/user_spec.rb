require 'spec_helper'

describe User do
  it "should be registerable" do
    @user = create(:user)
    expect(@user.devise_modules).to include :registerable
  end
end
