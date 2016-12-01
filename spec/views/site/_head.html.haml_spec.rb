require 'spec_helper'

RSpec.describe "/site/_head.html.haml", type: :view do
  it "should have csrf tags" do
      @current_site = double(name: 'name', tagline: 'tagline')
      expect(view).to receive(:csrf_meta_tags)

      render
  end
end
