require 'spec_helper'

describe "/site/_navbar.html.haml" do
  it "renders a login links" do
    link_class = {:events => '', :organizations => '', :venues => ''}
    expect(view).to receive(:link_class).exactly(3).times.and_return(link_class)
    expect(view).to receive(:user_signed_in?).and_return(false)


    current_site = double(:name => "foo")
    assign(:current_site, current_site)

    render
    expect(rendered).to include "Login"
  end
end