require 'spec_helper'

describe OrganizationsController do

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    let(:organization) { create(:organization) }

    it "should be successful" do
      get 'show', :id => organization.id
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    let(:organization) { create(:organization) }

    it "should be successful" do
      get 'edit', :id => organization.id
      response.should be_success
    end
  end

end
