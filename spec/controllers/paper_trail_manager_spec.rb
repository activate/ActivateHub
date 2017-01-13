require 'rails_helper'

RSpec.describe PaperTrailManager::ChangesController, type: :controller do
  describe "#index" do
    context "when the user is an admin" do
      before do
        sign_in create(:user, admin: true)
      end

      it "should load the admin pages" do
        get :index
        expect(response).to be_success
      end
    end

    context "when the user is not an admin" do
      before do
        sign_in create(:user, admin: false)
      end

      it "should not load the admin pages" do
        get :index
        expect(response).to be_redirect
      end
    end
  end
end
