require 'spec_helper'

describe "/devise/menu/_login_links.html.erb" do
  before do
    link_class = {:events => '', :organizations => '', :venues => ''}
    view.should_receive(:link_class).any_number_of_times.and_return(link_class)

    current_site = double(:name => "foo")
    assign(:current_site, current_site)
  end

  context "when we have a logged in user" do
    before do
      view.should_receive(:user_signed_in?).and_return(true)
    end

    it "should render a logout link" do
      render

      rendered.should_not include "Login"
      rendered.should include "Logout"
      rendered.should include "/users/sign_out"
    end
  end

  context "when logged out" do
    it "renders a login link" do
      render

      rendered.should include "Login"
      rendered.should include "/users/sign_in"
      rendered.should_not include "Logout"
    end
  end
end