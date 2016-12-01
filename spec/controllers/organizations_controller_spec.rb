require 'spec_helper'

RSpec.describe OrganizationsController, type: :controller do

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

      expect(Organization.last.venue).to eq venue
    end

    it "should create a new venue if needed and then associate it with the org" do
      params = {
          "organization"=>{
              "name"=>"Org 11"
          },
          "venue_name"=>"New One",
          "event"=>{
              "venue_id"=>""
          }
      }

      expect {
        post :create, params
      }.to change{ Venue.count }.by(1)

      expect(Organization.last.venue).to eq Venue.last
      expect(response).to redirect_to(edit_venue_url(Venue.last, :from_org => Organization.last.id))
    end
  end

  describe '#update' do
    it "should take the autocompleted event venue and apply it to the organization" do
      old_venue = create(:venue)
      organization = create(:organization, venue_id: old_venue.id)

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

      expect(Organization.last.venue).to eq new_venue
    end

    it "should create a new venue if needed and then associate it with the org" do
      org = create(:organization)
      params = {
          "id"=>org.id,
          "organization"=>{
              "name"=>"Org 11"
          },
          "venue_name"=>"New One",
          "event"=>{
              "venue_id"=>""
          }
      }

      expect {
        put :update, params
      }.to change{ Venue.count }.by(1)

      expect(Venue.last.title).to eq "New One"
      expect(Organization.last.venue).to eq Venue.last
      expect(response).to redirect_to(edit_venue_url(Venue.last, :from_org => Organization.last.id))
    end
  end

end
