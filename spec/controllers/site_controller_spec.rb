require 'spec_helper'

RSpec.describe SiteController, type: :controller do

  describe "#index" do
    it "should render requests for HTML successfully" do
      get :index
      expect(response).to redirect_to(events_path)
    end

    it "should redirect requests for non-HTML to events" do
      get :index, :format => "json"
      expect(response).to redirect_to(events_path(:format => "json"))
    end
  end

end
