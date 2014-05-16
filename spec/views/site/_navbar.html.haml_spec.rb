require 'spec_helper'

describe "/site/_navbar.html.haml" do
  it "renders a login link" do
    render
    rendered.should have_text(/Login/)
  end
end