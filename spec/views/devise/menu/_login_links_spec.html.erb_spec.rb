require 'rails_helper'

RSpec.describe "/devise/menu/_login_links.html.erb", type: :view do
  context "when we have a logged in user" do
    before do
      expect(view).to receive(:user_signed_in?).and_return(true)
    end

    it "should render a logout link" do
      render

      expect(rendered).to_not include "Login"
      expect(rendered).to include "Logout"
      expect(rendered).to include "/users/sign_out"
    end
  end

  context "when logged out" do
    before do
      expect(view).to receive(:user_signed_in?).and_return(false)
    end

    it "renders a login link" do
      render

      expect(rendered).to include "Login"
      expect(rendered).to include "/users/sign_in"
      expect(rendered).to_not include "Logout"
    end
  end
end
