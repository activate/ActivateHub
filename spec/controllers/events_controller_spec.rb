require 'spec_helper'

RSpec.describe EventsController, type: :controller do
  describe "#index" do
    render_views

    describe "as HTML" do
      it "should produce HTML" do
        get :index, :format => "html"

        expect(response.body).to have_selector ".events-index"
      end
    end

    describe "as XML" do
      describe "without events" do
        before do
          get :index, :format => "xml"

          @struct = Hash.from_xml(response.body)["events"]
        end

        it "should not have entries" do
          expect(@struct).to be_blank
        end
      end

      describe "with events" do
        before do
          create(:event_with_venue)
          create(:event_with_venue)

          get :index, :format => "xml"

          @struct = Hash.from_xml(response.body)["events"]
        end

        it "should return an array" do
          expect(@struct).to be_a_kind_of Array
        end

        it "should have entries" do
          expect(@struct).to be_present
        end

        it "should include venue details" do
          event = @struct.first
          venue = event["venue"]
          venue_title = venue["title"]  # Why XML? Why?
          expect(venue_title).to be_a_kind_of String
          expect(venue_title).to be_present
        end
      end
    end

    describe "as JSON" do
      it "should accept a JSONP callback" do
        post :index, :format => "json", :callback => "some_function"

        expect(response.body.split("\n").join).to match /\bsome_function\(.*\);?\s*$/
      end

      describe "without events" do
        before do
          post :index, :format => "json"

          @struct = ActiveSupport::JSON.decode(response.body)
        end

        it "should return an array" do
          expect(@struct).to be_a_kind_of Array
        end

        it "should not have entries" do
          expect(@struct).to be_empty
        end
      end

      describe "with events" do
        before do
          @event = create(:event_with_venue)
          @venue = @event.venue

          post :index, :format => "json"

          @struct = ActiveSupport::JSON.decode(response.body)
        end

        it "should return an array" do
          expect(@struct).to be_a_kind_of Array
        end

        it "should return an event" do
          event = @struct.first
          expect(event['id']).to eq @event.id
          expect(event['title']).to eq @event.title
        end

        it "should return an event's venue" do
          event = @struct.first
          venue = event['venue']

          expect(venue['id']).to eq @venue.id
          expect(venue['title']).to eq @venue.title
        end
      end
    end

    describe "as ATOM" do
      describe "without events" do
        before do
          post :index, :format => "atom"
          @struct = Hash.from_xml(response.body)
        end

        it "should be a feed" do
          expect(@struct['feed']['xmlns']).to be_present
        end

        it "should not have events" do
          expect(@struct['feed']['entry']).to be_blank
        end
      end

      describe "with events" do
        before do
          create(:event_with_venue)
          create(:event_with_venue)

          post :index, :format => "atom"

          @struct = Hash.from_xml(response.body)
        end

        let(:entries) { @struct["feed"]["entry"] }

        it "should be a feed" do
          expect(@struct['feed']['xmlns']).to be_present
        end

        it "should have entries" do
          expect(entries).to be_present
        end

        it "should have an event" do
          entry = entries.first
          record = Event.find(entry['id'][%r{(\d+)$}, 1])

          expect(Nokogiri.parse(entry['content']).search('.description p').inner_html).to eq record.description
          expect(entry['end_time']).to eq record.end_time.xmlschema
          expect(entry['start_time']).to eq record.start_time.xmlschema
          expect(entry['summary']).to be_present
          expect(entry['title']).to eq record.title
          expect(entry['updated']).to eq record.updated_at.xmlschema
          expect(entry['url']).to eq event_url(record)
        end
      end
    end

    describe "as iCalendar" do
      describe "without events" do
        before do
          post :index, :format => "ics"
        end

        it "should have a calendar" do
          expect(response.body).to match /BEGIN:VCALENDAR/
        end

        it "should not have events" do
          expect(response.body).to_not match /BEGIN:VEVENT/
        end
      end

      describe "with events" do
        before do
          @current_event = create(:event, :start_time => today + 1.hour)
          @past_event = create(:event, :start_time => today - 1.hour)

          post :index, :format => "ics"
        end

        it "should have a calendar" do
          expect(response.body).to match /BEGIN:VCALENDAR/
        end

        it "should have events" do
          expect(response.body).to match /BEGIN:VEVENT/
        end

        it "should render all future events" do
          expect(response.body).to match /SUMMARY:#{@current_event.title}/
        end

        it "should not render past events" do
          expect(response.body).to_not match /SUMMARY:#{@past_event.title}/
        end
      end
    end

    describe "and filtering by date range" do
      [:start, :end].each do |date_kind|
        describe "for #{date_kind} date" do
          before :each do
            @date_kind = date_kind
            @date_kind_other = \
              case date_kind
              when :start then :end
              when :end then :start
              else raise ArgumentError, "Unknown date_kind: #{date_kind}"
              end
          end

          it "should use the default if not given the parameter" do
            get :index, :date => {}
            expect(assigns["#{@date_kind}_date"]).to eq controller.send("default_#{@date_kind}_date")
            expect(flash[:failure]).to be_nil
          end

          it "should use the default if given a malformed parameter" do
            get :index, :date => "omgkittens"
            expect(assigns["#{@date_kind}_date"]).to eq controller.send("default_#{@date_kind}_date")
            expect(response.body).to have_selector(".failure", :text => 'malformed')
          end

          it "should use the default if given a missing parameter" do
            get :index, :date => {:foo => "bar"}
            expect(assigns["#{@date_kind}_date"]).to eq controller.send("default_#{@date_kind}_date")
            expect(response.body).to have_selector(".failure", :text => 'missing')
          end

          it "should use the default if given an empty parameter" do
            get :index, :date => {@date_kind => ""}
            expect(assigns["#{@date_kind}_date"]).to eq controller.send("default_#{@date_kind}_date")
            expect(response.body).to have_selector(".failure", :text => 'empty')
          end

          it "should use the default if given an invalid parameter" do
            get :index, :date => {@date_kind => "omgkittens"}
            expect(assigns["#{@date_kind}_date"]).to eq controller.send("default_#{@date_kind}_date")
            expect(response.body).to have_selector(".failure", :text => 'invalid')
          end

          it "should use the value if valid" do
            expected = Date.yesterday
            get :index, :date => {@date_kind => expected.to_s("%Y-%m-%d")}
            expect(assigns["#{@date_kind}_date"]).to eq expected
          end
        end
      end

      it "should return matching events" do
        # Given
        matching = [
          Event.create!(
            :title => "matching1",
            :start_time => Time.zone.parse("2010-01-16 00:00"),
            :end_time => Time.zone.parse("2010-01-16 01:00")
          ),
          Event.create!(:title => "matching2",
            :start_time => Time.zone.parse("2010-01-16 23:00"),
            :end_time => Time.zone.parse("2010-01-17 00:00")
          ),
        ]

        non_matching = [
          Event.create!(
            :title => "nonmatchingbefore",
            :start_time => Time.zone.parse("2010-01-15 23:00"),
            :end_time => Time.zone.parse("2010-01-15 23:59")
          ),
          Event.create!(
            :title => "nonmatchingafter",
            :start_time => Time.zone.parse("2010-01-17 00:01"),
            :end_time => Time.zone.parse("2010-01-17 01:00")
          ),
        ]

        # When
        get :index, :date => {:start => "2010-01-16", :end => "2010-01-16"}
        results = assigns[:events]

        # Then
        expect(results.size).to eq 2
        expect(results).to eq matching
      end
    end
  end

  describe "#show" do
    it "should show an event" do
      event = create(:event, :start_time => now)
      expect(Event).to receive(:find).and_return(event)

      get "show", :id => 1234
      expect(response).to be_success
    end

    it "should redirect from a duplicate event to its master" do
      master = create(:event, :id => 4321)
      event = Event.new(:start_time => now, :duplicate_of => master)
      expect(Event).to receive(:find).and_return(event)

      get "show", :id => 1234
      expect(response).to redirect_to(event_path(master))
    end

    it "should show an error when asked to display a non-existent event" do
      expect(Event).to receive(:find).and_raise(ActiveRecord::RecordNotFound)

      get "show", :id => 1234
      expect(response).to redirect_to(events_path)
      expect(flash[:failure]).to_not be_blank
    end
  end

  describe "when creating and updating events" do
    before(:each) do
      # Fields marked with "###" may be filled in by examples to alter behavior
      @params = {
        :end_date       => "2008-06-04",
        :start_date     => "2008-06-03",
        :event => {
          "title"       => "MyVenue",
          "url"         => "http://my.venue",
          "description" => "Wheeeee",
          "type_ids"    => [],
          "topic_ids"   => [],
        },
        :end_time       => "",
        :start_time     => ""
      }
      @venue = build(:venue, :id => 12)
      @event = build(:event, :id => 34, :venue => @venue)
    end

    describe "#new" do
      it "should display form for creating new event" do
        get "new"
        expect(response).to be_success
        expect(response).to render_template :new
      end
    end

    describe "#create" do
      render_views

      it "should create a new event without a venue" do
        expect(Event).to receive(:new).with(@params[:event]).and_return(@event)
        allow(@event).to receive(:associate_with_venue).with(@params[:venue_name])
        allow(@event).to receive(:venue).and_return(nil)
        expect(@event).to receive(:save).and_return(true)

        post "create", @params
        expect(response).to redirect_to(event_path(@event))
      end

      it "should associate a venue based on a given venue id" do
        @params[:event]["venue_id"] = @venue.id.to_s
        allow(Event).to receive(:new).with(@params[:event]).and_return(@event)
        expect(@event).to receive(:associate_with_venue).with(@venue.id)
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:save).and_return(true)

        post "create", @params
      end

      it "should associate a venue based on a given venue name" do
        @params[:venue_name] = "My Venue"
        expect(Event).to receive(:new).with(@params[:event]).and_return(@event)
        expect(@event).to receive(:associate_with_venue).with("My Venue")
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:save).and_return(true)

        post "create", @params
      end

      it "should associate a venue by id when both an id and a name are provided" do
        @params[:event]["venue_id"] = @venue.id.to_s
        @params[:venue_name] = "Some Event"
        expect(Event).to receive(:new).with(@params[:event]).and_return(@event)
        expect(@event).to receive(:associate_with_venue).with(@venue.id)
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:save).and_return(true)

        post "create", @params
      end

      it "should create a new event for an existing venue" do
        @params[:venue_name] = "Old Venue"
        expect(Event).to receive(:new).with(@params[:event]).and_return(@event)
        allow(@event).to receive(:associate_with_venue).with(@params[:venue_name])
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:save).and_return(true)
        allow(@venue).to receive(:new_record?).and_return(false)

        post "create", @params
        expect(response).to redirect_to(event_path(@event))
      end

      it "should create a new event and new venue, and redirect to venue edit form" do
        @params[:venue_name] = "New Venue"
        expect(Event).to receive(:new).with(@params[:event]).and_return(@event)
        allow(@event).to receive(:associate_with_venue).with(@params[:venue_name])
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:save).and_return(true)
        allow(@venue).to receive(:new_record?).and_return(true)

        post "create", @params
        expect(response).to redirect_to(edit_venue_url(@venue, :from_event => @event.id))
      end

      it "should catch errors and redisplay the new event form" do
        post "create"
        expect(response).to render_template :new
      end

      it "should stop evil robots" do
        post "create", :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
        expect(response).to render_template :new
        expect(flash[:failure]).to match /evil robot/i
      end

      it "should not allow too many links in the description" do
        @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
        DESC
        post "create", @params
        expect(response).to render_template :new
        expect(flash[:failure]).to match /too many links/i
      end

      it "should accept HTTP-rich presentation descriptions without too many links" do
        @params[:event][:description] = <<-DESC
          I hereby offer to give a presentation at the August ruby meeting about the faraday
          gem (https://github.com/lostisland/faraday) and how compares to or compliments other
          HTTP client libraries such as httparty (https://github.com/jnunemaker/httparty).

          --

          I wouldn't mind seeing a PDX.pm talk about HTTP::Tiny vs Net::HTTP::Tiny vs Net::HTTP
          vs HTTP::Client vs HTTP::Client::Parallel
        DESC
        post "create", @params
        expect(flash[:failure]).to be_nil
      end

      it "should allow the user to preview the event" do
        event = Event.new(:title => "Awesomeness")
        expect(Event).to receive(:new).and_return(event)

        expect(event).to_not receive(:save)

        post "create", :event => { :title => "Awesomeness" },
                        :start_time => now, :start_date => today,
                        :end_time => now, :end_date => today,
                        :preview => "Preview",
                        :venue_name => "This venue had better not exist"
        expect(response).to render_template :new
        expect(response.body).to have_selector '.event-preview'
        expect(event).to be_valid
      end

      it "should create an event for an existing venue" do
        venue = create(:venue)

        post "create",
          :start_time => now.strftime("%Y-%m-%d"),
          :end_time   => (now + 1.hour).strftime("%Y-%m-%d"),
          :event      => {
            :title      => "My Event",
            :tag_list   => ",,foo,bar, baz,",
          },
          :venue_name => venue.title

        expect(response).to be_redirect

        expect(flash[:success]).to be_present

        event = assigns[:event]
        expect(event.title).to eq "My Event"
        expect(event.venue.title).to eq venue.title
        expect(event.venue.id).to eq venue.id
        expect(event.tag_list.to_a.sort).to eq %w[bar baz foo]
      end
    end

    describe "edit" do
      context "when a user is logged in" do
        it "should display form for editing event" do
          sign_in create(:user)

          get :edit, :id => create(:event).id
          expect(response).to be_success
          expect(response).to render_template :edit
        end
      end

      context "when a user is not logged in" do
        it "should redirect the user to sign in" do
          get :edit, :id => create(:event).id
          expect(response).to redirect_to(user_session_path)
        end
      end
    end

    describe "#update" do
      before(:each) do
        @event = build(:event_with_venue, :id => 42)
        @venue = @event.venue
        @params = @params.merge(:id => 42)
        allow(Event).to receive(:find).and_return(@event)
      end

      it "should update an event without a venue" do
        expect(Event).to receive(:find).and_return(@event)
        allow(@event).to receive(:associate_with_venue).with(@params[:venue_name])
        allow(@event).to receive(:venue).and_return(nil)
        expect(@event).to receive(:attributes=).with(@params[:event]).and_call_original
        expect(@event).to receive(:save).and_return(true)

        put "update", @params
        expect(response).to redirect_to(event_path(@event))
      end

      it "should associate a venue based on a given venue id" do
        @params[:event]["venue_id"] = @venue.id.to_s
        expect(Event).to receive(:find).and_return(@event)
        expect(@event).to receive(:associate_with_venue).with(@venue.id)
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:attributes=).with(@params[:event]).and_call_original
        expect(@event).to receive(:save).and_return(true)

        put "update", @params
      end

      it "should associate a venue based on a given venue name" do
        @params[:venue_name] = "Some Event"
        expect(Event).to receive(:find).and_return(@event)
        expect(@event).to receive(:associate_with_venue).with("Some Event")
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:attributes=).with(@params[:event]).and_call_original
        expect(@event).to receive(:save).and_return(true)

        put "update", @params
      end

      it "should associate a venue by id when both an id and a name are provided" do
        @params[:event]["venue_id"] = @venue.id.to_s
        @params[:venue_name] = "Some Event"
        expect(Event).to receive(:find).and_return(@event)
        expect(@event).to receive(:associate_with_venue).with(@venue.id)
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:attributes=).with(@params[:event]).and_call_original
        expect(@event).to receive(:save).and_return(true)

        put "update", @params
      end

      it "should update an event and associate it with an existing venue" do
        @params[:venue_name] = "Old Venue"
        expect(Event).to receive(:find).and_return(@event)
        allow(@event).to receive(:associate_with_venue).with(@params[:venue_name])
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:attributes=).with(@params[:event]).and_call_original
        expect(@event).to receive(:save).and_return(true)
        allow(@venue).to receive(:new_record?).and_return(false)

        put "update", @params
        expect(response).to redirect_to(event_path(@event))
      end

      it "should update an event and create a new venue, and redirect to the venue edit form" do
        @params[:venue_name] = "New Venue"
        expect(Event).to receive(:find).and_return(@event)
        allow(@event).to receive(:associate_with_venue).with(@params[:venue_name])
        allow(@event).to receive(:venue).and_return(@venue)
        expect(@event).to receive(:attributes=).with(@params[:event]).and_call_original
        expect(@event).to receive(:save).and_return(true)
        allow(@venue).to receive(:new_record?).and_return(true)

        put "update", @params
        expect(response).to redirect_to(edit_venue_url(@venue, :from_event => @event.id))
      end

      it "should catch errors and redisplay the new event form" do
        expect(Event).to receive(:find).and_return(@event)
        allow(@event).to receive(:associate_with_venue)
        allow(@event).to receive(:venue).and_return(nil)
        expect(@event).to receive(:save).and_return(false)

        put "update", :id => 1234
        expect(response).to render_template :edit
      end

      it "should stop evil robots" do
        put "update", :id => 1234, :trap_field => "I AM AN EVIL ROBOT, I EAT OLD PEOPLE'S MEDICINE FOR FOOD!"
        expect(response).to render_template :edit
        expect(flash[:failure]).to match /evil robot/i
      end

      it "should not allow too many links in the description" do
        @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
        DESC
        put "update", @params
        expect(response).to render_template :edit
        expect(flash[:failure]).to match /too many links/i
      end

      it "should allow too many links in the description if already has too many" do
        # if an event came in with too many links to begin with (imported), we
        # should allow it to have those links until it returns below threshold
        @event.description = <<-DESC
          old description...
          http://example.com
          https://example.com
          http://example.net
          https://example.net
        DESC
        @event.changed_attributes.delete('description') # sets up description_was

        @params[:event][:description] = <<-DESC
          http://example.com
          https://example.com
          http://example.net
          https://example.net
        DESC
        put "update", @params
        expect(response).to redirect_to(event_path(@event))
      end

      it "should allow the user to preview the event" do
        tags = []
        expect(tags).to receive(:reload)

        expect(Event).to receive(:find).and_return(@event)
        expect(@event).to_not receive(:update_attributes)
        expect(@event).to receive(:attributes=)
        expect(@event).to receive(:valid?).and_return(true)
        expect(@event).to receive(:tags).and_return(tags)

        put "update", @params.merge(:preview => "Preview")
        expect(response).to render_template :edit
      end

    end

    describe "#clone" do
      context "when a user is not logged in" do
        it "redirects the user signin" do
          event = create(:event)
          get :clone, :id => event.id

          expect(response).to redirect_to(user_session_path)
        end
      end

      context "when a user is logged in" do
        before do
          user = create(:user)
          sign_in user
          @event = create(:event)

          get "clone", :id => @event.id
        end

        it "should build an unsaved record" do
          record = assigns[:event]
          expect(record).to be_a_new_record
          expect(record.id).to be_nil
        end

        it "should build a cloned record similar to the existing record" do
          record = assigns[:event]
          %w[title description venue_id venue_details].each do |field|
            expect(record.attributes[field]).to eq @event.attributes[field]
          end
        end

        it "should display a new event form" do
          expect(response).to be_success
          expect(response).to render_template :new
        end

        it "should have notice with cloning instructions" do
          expect(flash[:success]).to match /clone/i
        end
      end
    end
  end

  describe "#duplicates" do
    context "when the user is a normal user" do
      before do
        sign_in create(:user, admin: false)
      end

      it "does not allow them to clean duplicates" do
        get :duplicates, :type => 'title'

        expect(response).to redirect_to root_url
      end
    end

    context "when the user is an admin" do
      before do
        sign_in create(:user, admin: true)
      end

      render_views

      it "should find current duplicates and not past duplicates" do
        current_master = create(:event, :title => "Current")
        current_duplicate = create(:event, :title => current_master.title)

        past_master = create(:event, :title => "Past", :start_time => now - 2.days)
        past_duplicate = create(:event, :title => past_master.title, :start_time => now - 1.day)

        get 'duplicates', :type => 'title'

        # Current duplicates
        assigns[:grouped_events].select{|keys,values| keys.include?(current_master.title)}.tap do |events|
          expect(events).to_not be_empty
          expect(events.first.last.size).to eq 2
        end

        # Past duplicates
        expect(assigns[:grouped_events].select{|keys,values| keys.include?(past_master.title)}).to be_empty
      end

      it "should redirect duplicate events to their master" do
        event_master = create(:event)
        event_duplicate = create(:event)

        get 'show', :id => event_duplicate.id
        expect(response).to_not be_redirect
        expect(assigns(:event).id).to eq event_duplicate.id

        event_duplicate.duplicate_of = event_master
        event_duplicate.save!

        get 'show', :id => event_duplicate.id
        expect(response).to be_redirect
        expect(response).to redirect_to(event_url(event_master.id))
      end

      it "should display an error message if given invalid arguments" do
        get 'duplicates', :type => 'omgwtfbbq'

        expect(response).to be_success
        expect(response.body).to have_selector('.failure', :text => 'omgwtfbbq')
      end
    end


  end

  describe "#search" do
    it "should search" do
      expect(Event).to receive(:search_keywords_grouped_by_currentness).and_return({:current => [], :past => []})

      post :search, :query => "myquery"
    end

    it "should fail if given no search query" do
      post :search

      expect(flash[:failure]).to_not be_blank
      expect(response).to redirect_to(root_path)
    end

    it "should be able to only return current events" do
      expect(Event).to receive(:search).with("myquery", :order => nil, :skip_old => true).and_return([])

      post :search, :query => "myquery", :current => "1"
    end

    describe "by tag" do
      it "should be able to only return events matching specific tag" do
        expect(Event).to receive(:tagged_with).with("foo", :order => "events.start_time").and_return(Event.where('1 = 0'))

        post :search, :tag => "foo"
      end

      it "should warn if user tries ordering tags by score" do
        expect(Event).to receive(:tagged_with).with("foo", :order => "events.start_time").and_return(Event.where('1 = 0'))

        post :search, :tag => "foo", :order => "score"
        expect(flash[:failure]).to_not be_blank
      end

      it "should warn if user tries ordering tags by invalid order" do
        expect(Event).to receive(:tagged_with).with("foo", :order => "events.start_time").and_return(Event.where('1 = 0'))

        post :search, :tag => "foo", :order => "kittens"
        expect(flash[:failure]).to_not be_blank
      end

      # TODO Add subscribe and other links
    end

    describe "when returning results" do
      render_views

      let(:current_event) { create(:event_with_venue) }
      let(:current_event_2) { create(:event_with_venue) }
      let(:past_event) { create(:event_with_venue) }
      let(:results) do
        {
          :current => [current_event, current_event_2],
          :past    => [past_event],
        }
      end

      before do
        expect(Event).to receive(:search_keywords_grouped_by_currentness).and_return(results)
      end

      describe "in HTML format" do
        before do
          post :search, :query => "myquery", :format => "html"
        end

        it "should assign matching events" do
          expect(assigns[:events]).to eq results[:past] + results[:current]
        end

        it "should render matching events" do
          have_selector ".events-view" do
            have_selector ".event-title a", :href => event_url(results[:past])
            have_selector ".event-title a", :href => event_url(results[:current])
          end
        end

        describe "sidebar" do
          it "should have iCalendar feed" do
            have_selector ".sidebar a", :href => search_events_url(:query => @query, :format => "ics", :protocol => "webcal")
          end

          it "should have Atom feed" do
            have_selector ".sidebar a", :href => search_events_url(:query => @query, :format => "atom")
          end

          it "should have Google subscription" # TODO
        end
      end

      describe "in XML format" do

        it "should produce XML" do
          post :search, :query => "myquery", :format => "xml"

          hash = Hash.from_xml(response.body)
          expect(hash["events"]).to be_a_kind_of Array
        end

        it "should include venue details" do
          post :search, :query => "myquery", :format => "xml"

          hash = Hash.from_xml(response.body)
          event = hash["events"].first
          venue = event["venue"]
          venue_title = venue["title"]
          expect(venue_title).to be_a_kind_of String
          expect(venue_title.length).to be_present
        end

      end

      describe "in JSON format" do

        it "should produce JSON" do
          post :search, :query => "myquery", :format => "json"

          struct = ActiveSupport::JSON.decode(response.body)
          expect(struct).to be_a_kind_of Array
        end

        it "should accept a JSONP callback" do
          post :search, :query => "myquery", :format => "json", :callback => "some_function"

          expect(response.body.split("\n").join).to match /\bsome_function\(.*\);?\s*$/
        end

        it "should include venue details" do
          post :search, :query => "myquery", :format => "json"

          struct = ActiveSupport::JSON.decode(response.body)
          event = struct.first
          expect(event["venue"]["title"]).to be_a_kind_of String
          expect(event["venue"]["title"].length).to be_present
        end

      end

      it "should produce ATOM" do
        post :search, :query => "myquery", :format => "atom"

        hash = Hash.from_xml(response.body)
        expect(hash["feed"]["entry"]).to be_a_kind_of Array
      end

      describe "in ICS format" do

        it "should produce ICS" do
          post :search, :query => "myquery", :format => "ics"

          expect(response.body).to match /BEGIN:VEVENT/
        end

        it "should produce events matching the query" do
          post :search, :query => "myquery", :format => "ics"
          expect(response.body).to match /SUMMARY:#{current_event_2.title}/
          expect(response.body).to match /SUMMARY:#{past_event.title}/
        end
      end
    end
  end

  describe "#destroy" do
    context "when the user is logged in" do
      it "should destroy events" do
        sign_in create(:user)
        event = build(:event)
        expect(event).to receive(:destroy)
        expect(Event).to receive(:find).and_return(event)

        delete 'destroy', :id => 1234
        expect(response).to redirect_to(events_url)
      end
    end

    context "when the user is logged out" do
      it "they are redirected to signin" do
        event = create(:event)

        delete 'destroy', :id => event.id
        expect(response).to redirect_to(user_session_path)
      end
    end
  end
end
