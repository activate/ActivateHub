require 'spec_helper'

describe UsersController do

  describe "GET :show" do
    it "should be successful" do
      user = create(:user)
      get :show, format: user.id

      response.should be_success
      expect(assigns(:user)).to eq(user)
    end
  end
end
