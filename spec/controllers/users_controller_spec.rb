require 'spec_helper'

RSpec.describe UsersController, type: :controller do

  describe "GET :show" do
    it "should be successful" do
      user = create(:user)
      get :show, :params => { format: user.id }

      expect(response).to be_success
      expect(assigns(:user)).to eq(user)
    end
  end
end
