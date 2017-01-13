require 'rails_helper'

RSpec.describe OrganizationsController, type: :controller do

  describe "GET 'index'" do
    it "should be successful" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'show'" do
    let(:organization) { create(:organization) }

    it "should be successful" do
      get 'show', :params => { :id => organization.id }
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it "should be successful" do
      get 'new'
      expect(response).to be_success
    end
  end

  describe "GET 'edit'", :requires_user do
    def test_authenticated_request
      get :edit, :params => { :id => create(:organization).id }
    end

    let(:organization) { create(:organization) }

    it "should be successful" do
      get 'edit', :params => { :id => organization.id }
      expect(response).to be_success
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
        post :create, params: params
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
        post :create, :params => params
      }.to change{ Venue.count }.by(1)

      expect(Organization.last.venue).to eq Venue.last
      expect(response).to redirect_to(edit_venue_url(Venue.last, :from_org => Organization.last.id))
    end
  end

  describe '#update', :requires_user do
    def test_authenticated_request
      venue = create(:venue)
      org = create(:organization, :venue_id => venue.id)
      put :update, :params => {
        :id => org.id,
        :organization => org.attributes,
        :event => { :venue_id => venue.id },
      }
    end

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

      put :update, :params => params

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
        put :update, :params => params
      }.to change{ Venue.count }.by(1)

      expect(Venue.last.title).to eq "New One"
      expect(Organization.last.venue).to eq Venue.last
      expect(response).to redirect_to(edit_venue_url(Venue.last, :from_org => Organization.last.id))
    end
  end

  describe "#destroy", :requires_user do
    def test_authenticated_request
      delete :destroy, :params => { :id => create(:organization).id }
    end
  end

end
