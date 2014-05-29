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

  describe '#create' do
    it "should take the autocompleted event venue and apply it to the organization" do
      venue = create(:venue)
      params = {
          "organization"=>{
              "name"=>"Org 11", "url"=>"", "description"=>"", "contact_name"=>"", "email"=>"", "topic_ids"=>["", ""]
          },
          "venue_name"=>venue.title,
          "event"=>{
              "venue_id"=>venue.id
          }
      }

      expect {
        post :create, params
      }.to change{Organization.count}.by(1)

      expect(Organization.last.default_venue).to eq venue
    end
  end

  describe '#update' do
    it "should take the autocompleted event venue and apply it to the organization" do
      old_venue = create(:venue)
      organization = create(:organization, default_venue_id: old_venue.id)

      new_venue = create(:venue)
      params = {
          "organization"=>organization.attributes,
          "venue_name"=>new_venue.title,
          "event"=>{
              "venue_id"=>new_venue.id
          },
          "id"=>organization.id
      }

      put :update, params

      expect(Organization.last.default_venue).to eq new_venue
    end
  end

end
