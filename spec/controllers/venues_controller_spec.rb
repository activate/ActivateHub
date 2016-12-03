require 'spec_helper'

RSpec.describe VenuesController, type: :controller do
  render_views

  #Delete this example and add some real ones
  it "should use VenuesController" do
    expect(controller).to be_an_instance_of VenuesController
  end

  it "should redirect duplicate venues to their master" do
    venue_master = create(:venue)
    venue_duplicate = create(:venue)

    # No redirect when they're unique
    get 'show', :params => { :id => venue_duplicate.id }
    expect(response).to_not be_redirect
    expect(assigns(:venue).id).to eq venue_duplicate.id

    # Mark as duplicate
    venue_duplicate.duplicate_of = venue_master
    venue_duplicate.save!

    # Now check that redirection happens
    get 'show', :params => { :id => venue_duplicate.id }
    expect(response).to be_redirect
    expect(response).to redirect_to(venue_url(venue_master.id))
  end

  it "should display an error message if given invalid arguments" do
    get :duplicates, :params => { :type => 'omgwtfbbq' }

    expect(response).to be_success
    expect(response.body).to have_selector('.failure', :text => 'omgwtfbbq')
  end

  describe "when creating venues" do
    it "should stop evil robots" do
      post :create, :params => { :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!" }
      expect(response).to render_template :new
    end
  end

  describe "when updating venues" do
    before do
      @venue = build(:venue, :versions => [])
      allow(Venue).to receive(:find).and_return(@venue)
    end

    it "should stop evil robots" do
      put :update, :params => { :id => '1', :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!" }
      expect(response).to render_template :edit
    end

    describe "redirection" do
      it "when the user comes from an org creation page" do
        org = create(:organization)
        put :update, :params => { :id => '1', :from_org => org.id }
        expect(response).to redirect_to organization_url(org)
      end

      it "when the user comes from an event creation page" do
        event = create(:event)
        put :update, :params => { :id => '1', :from_event => event.id }
        expect(response).to redirect_to event_url(event)
      end
    end
  end

  describe "#index" do
    it "can be scoped by type of events held at that venue" do
      social = create(:type, name: "social")
      social_venue = create(:venue, title:"social venue")
      social_event = create(:event, venue_id: social_venue.id)
      social_event.types << social
      
      meeting = create(:type, name: "meeting")
      meeting_venue = create(:venue, title:"meeting venue")
      meeting_event = create(:event, venue_id: meeting_venue.id)
      meeting_event.types << meeting

      get :index, :params => { type: social.name }

      expect(assigns(:types).map(&:name)).to match_array ["social", "meeting"]
      expect(assigns(:selected_types)).to eq [social.name]
      expect(assigns(:newest_venues).map(&:title)).to eq ["social venue"]
      expect(assigns(:most_active_venues).map(&:title)).to eq ["social venue"]
      expect(assigns(:venues).map(&:title)).to eq ["social venue"]
    end
  end

  describe "when rendering the venues index" do
    before do
      @open_venue = create(:venue, :title => 'Open Town', :description => 'baz', :wifi => false)
      @closed_venue = create(:venue, :title => 'Closed Down', :closed => true, :wifi => false)
      @wifi_venue = create(:venue, :title => "Internetful", :wifi => true)
    end

    describe "with no parameters" do
      before do
        get :index
      end

      it "should assign @most_active_venues and @newest_venues by default" do
        get :index
        expect(assigns[:most_active_venues]).to_not be_nil
        expect(assigns[:newest_venues]).to_not be_nil
      end

      it "should not included closed venues" do
        expect(assigns[:newest_venues]).to_not include @closed_venue
      end
    end

    describe "and showing all venues" do
      it "should include closed venues when asked to with the include_closed parameter" do
        get :index, :params => { :all => '1', :include_closed => '1' }
        expect(assigns[:venues]).to include @closed_venue
      end

      it "should include ONLY closed venues when asked to with the closed parameter" do
        get :index, :params => { :all => '1', :closed => '1' }
        expect(assigns[:venues]).to include @closed_venue
        expect(assigns[:venues]).to_not include @open_venue
      end
    end

    describe "when searching" do
      describe "for public wifi (and no keyword)" do
        before do
          get :index, :params => { :query => '', :wifi => '1' }
        end

        it "should only include results with public wifi" do
          expect(assigns[:venues]).to include @wifi_venue
          expect(assigns[:venues]).to_not include @open_venue
        end
      end

      describe "when searching by keyword" do
        it "should find venues by title" do
          get :index, :params => { :query => 'Open Town' }
          expect(assigns[:venues]).to include @open_venue
          expect(assigns[:venues]).to_not include @wifi_venue
        end
        it "should find venues by description" do
          get :index, :params => { :query => 'baz' }
          expect(assigns[:venues]).to include @open_venue
          expect([:venues]).to_not include @wifi_venue
        end

        describe "and requiring public wifi" do
          it "should not find venues without public wifi" do
            get :index, :params => { :query => 'baz', :wifi => '1' }
            expect(assigns[:venues]).to_not include @open_venue
            expect(assigns[:venues]).to_not include @wifi_venue
          end
        end
      end

      describe "when searching by title (for the ajax selector)" do
        it "should find venues by title" do
          get :index, :params => { :term => 'Open Town' }
          expect(assigns[:venues]).to include @open_venue
          expect(assigns[:venues]).to_not include @wifi_venue
        end
        it "should NOT find venues by description" do
          get :index, :params => { :term => 'baz' }
          expect(assigns[:venues]).to_not include @open_venue
        end
        it "should NOT find closed venues" do
          get :index, :params => { :term => 'closed' }
          expect(assigns[:venues]).to_not include @closed_venue
        end
      end
    end

    it "should be able to return events matching specific tag" do
      expect(Venue).to receive(:tagged_with).with("foo").and_return(Venue.where('1 = 0'))
      get :index, :params => { :tag => "foo" }
    end

    describe "in JSON format" do
      it "should produce JSON" do
        get :index, :params => { :format => "json" }

        struct = ActiveSupport::JSON.decode(response.body)
        expect(struct).to be_a_kind_of Array
      end

      it "should accept a JSONP callback" do
        get :index, :params => { :format => "json", :callback => "some_function" }, :xhr => true

        expect(response.body.split("\n").join).to match /\bsome_function\(.*\);?\s*$/
      end
    end

  end

  describe "when showing venues" do
    describe "in JSON format" do
      describe "with events" do
        before do
          @venue = create(:venue, :id => 123)
        end

        it "should produce JSON" do
          get :show, :params => { :id => @venue.to_param, :format => "json" }

          struct = ActiveSupport::JSON.decode(response.body)
          expect(struct).to be_a_kind_of Hash
          %w[id title description address].each do |field|
            expect(struct[field]).to eq @venue.send(field)
          end
        end

        it "should accept a JSONP callback" do
          get :show, :params => { :id => @venue.to_param, :format => "json", :callback => "some_function" }, :xhr => true

          expect(response.body.split("\n").join).to match /\bsome_function\(.*\);?\s*$/
        end
      end
    end

    describe "in HTML format" do
      describe "venue with future and past events" do
        before do
          @venue = create(:venue)
          @future_event = create(:event, :venue => @venue)
          @past_event = create(:event, :venue => @venue,
            :start_time => Time.zone.now - 1.week + 1.hour,
            :end_time => Time.zone.now - 1.week + 2.hours)

          get :show, :params => { :id => @venue.to_param, :format => "html" }
          expect(response).to be_success
        end

        it "should have a venue" do
          expect(response.body).to have_selector(".location .fn", :text => @venue.title)
        end

        it "should have a future event" do
          expect(response.body).to have_selector(".future-events .event-title", :text => @future_event.title)
        end

        it "should have a past event" do
          expect(response.body).to have_selector(".past-events .event-title", :text => @past_event.title)
        end
      end
    end

    describe "as an iCalendar" do
      before do
        @venue = create(:venue)
        @future_event = create(:event, :venue => @venue, :start_time => today + 1.hour)
        @past_event = create(:event, :venue => @venue, :start_time => today - 1.hour)

        get :show, :params => { :id => @venue.to_param, :format => "ics" }
      end

      it "should have a calendar" do
        expect(response.body).to match /BEGIN:VCALENDAR/
      end

      it "should have events" do
        expect(response.body).to match /BEGIN:VEVENT/
      end

      it "should render all future events" do
        expect(response.body).to match /SUMMARY:#{@future_event.title}/
      end

      it "should render all past events" do
        expect(response.body).to match /SUMMARY:#{@past_event.title}/
      end
    end

  end

  describe "DELETE" do
    describe "when deleting a venue without events" do
      before do
        @venue = create(:venue)
      end

      shared_examples_for "destroying a Venue record without events" do
        it "should destroy the Venue record" do
          expect(lambda { Venue.find(@venue.id) }).to raise_error ActiveRecord::RecordNotFound
        end
      end

      describe "and rendering HTML" do
        before do
          delete :destroy, :params => { :id => @venue.id }
        end

        it_should_behave_like "destroying a Venue record without events"

        it "should display a success message" do
          expect(flash[:success]).to be_present
        end

        it "should redirect to the venues listing" do
          expect(response).to redirect_to(venues_path)
        end
      end

      describe "and rendering XML" do
        render_views

        before do
          delete :destroy, :params => { :id => @venue.id, :format => "xml" }
        end

        it_should_behave_like "destroying a Venue record without events"

        it "should return a success status" do
          expect(response).to be_success
        end
      end
    end

    describe "when deleting a venue with events" do
      before do
        @event = create(:event_with_venue)
        @venue = @event.venue
      end

      shared_examples_for "destroying a Venue record with events" do
        it "should not destroy the Venue record" do
          expect(Venue.find(@venue.id)).to be_present
        end
      end

      describe "and rendering HTML" do
        before do
          delete :destroy, :params => { :id => @venue.id }
        end

        it_should_behave_like "destroying a Venue record with events"

        it "should display a failure message" do
          expect(flash[:failure]).to be_present
        end

        it "should redirect to the venue page" do
          expect(response).to redirect_to(venue_path(@venue))
        end
      end

      describe "and rendering XML" do
        before do
          delete :destroy, :params => { :id => @venue.id, :format => "xml" }
        end

        it_should_behave_like "destroying a Venue record with events"

        it "should return unprocessable entity status" do
          expect(response.code.to_i).to eq 422
        end

        it "should describing the problem" do
          expect(response.body).to match /cannot/i
        end
      end
    end
  end
end
