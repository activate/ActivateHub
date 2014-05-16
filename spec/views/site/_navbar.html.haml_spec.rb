require 'spec_helper'

describe "/site/_navbar.html.haml" do
  it "renders a login link" do
    link_class = {:events => '', :organizations => '', :venues => ''}
    view.should_receive(:link_class).any_number_of_times.and_return(link_class)

    current_site = double(:name => "foo")
    assign(:current_site, current_site)

    render
    rendered.should include "Login"
  end
end