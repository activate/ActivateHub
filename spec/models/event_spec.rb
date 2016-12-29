require 'spec_helper'

RSpec.describe Event, type: :model do

  describe "when an event has no venue" do
    context "when the event is affiliated with an organization that has a default venue" do
      before do
        @venue = create(:venue)
        @organization = create(:organization, venue_id: @venue.id)
      end

      it "inherits the default venue from the organization" do
        expect(create(:event, organization_id: @organization.id).venue).to eq @venue
      end
    end

    context "when the event is already affiliated with a empty venue" do
      before do
        @org_venue = create(:venue, title: "Org Venue")
        @organization = create(:organization, venue_id: @org_venue.id)

        blank_title_from_associate_with_venue = ""
        @venue = build(:venue, title: blank_title_from_associate_with_venue)
      end

      it "uses the organization's default venue" do
        event = build(:event, organization_id: @organization.id)
        event.venue = @venue
        event.save

        expect(event.reload.venue.title).to eq @org_venue.title
      end
    end
  end

  describe "url validations" do
    it "should add http:// to websites that don't have it" do
      event = build(:event, url: "www.example.com")
      event.save!

      expect(event.reload.valid?).to be true
    end

    it "should validate on a regex" do
      expect("http://www.example.com".match(Event::WEBSITE_FORMAT)).to be_truthy
    end
  end

  describe "in general"  do
    it "should be valid" do
      event = Event.new(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'))
      expect(event).to be_valid
    end

    it "should add a http:// prefix to urls without one" do
      event = Event.new(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'), :url => 'google.com')
      expect(event).to be_valid
    end

    describe "#description" do
      it "returns nil if no value" do
        # it used to return "" for a time due to explicit :to_s
        expect(Event.new.description).to eq nil
      end
    end

    describe "#end_time" do
      it "default to start_time if nil" do
        start_time = 1.week.from_now
        expect(Event.new(:start_time => start_time).end_time).to eq start_time
      end
    end

    describe "#title" do
      it "returns nil if no value" do
        # it used to return "" for a time due to explicit :to_s
        expect(Event.new.title).to eq nil
      end
    end

  end

  describe "when checking time status" do
    it "should be old if event ended before today" do
      expect(build(:event, :start_time => today - 1.hour)).to be_old
    end

    it "should be current if event is happening today" do
      expect(build(:event, :start_time => today + 1.hour)).to be_current
    end

    it "should be ongoing if it began before today but ends today or later" do
      expect(build(:event, :start_time => today - 1.day, :end_time => today + 1.day)).to be_ongoing
    end

    it "should be considered a multi-day event if it spans multiple days" do
      expect(build(:event, :start_time => today - 1.day, :end_time => now + 1.day)).to be_multiday
    end

    it "should be considered a multi-day event if it crosses a day boundry and is longer than the minimum duration (#{Event::MIN_MULTIDAY_DURATION.inspect})" do
      expect(Event.new(:start_time => today - 1.second, :end_time => today + Event::MIN_MULTIDAY_DURATION)).to be_multiday
    end

    it "should not be considered a multi-day event if it crosses a day boundry, but is not longer than the minimum duration (#{Event::MIN_MULTIDAY_DURATION.inspect})" do
      expect(Event.new(:start_time => today - 1.second, :end_time => today - 1.second + Event::MIN_MULTIDAY_DURATION)).to_not be_multiday
    end
  end

  describe "dealing with tags" do
    before do
      @tags = "some, tags"
      @event = Event.new(:title => "Tagging Day", :start_time => now)
    end

    it "should be taggable" do
      expect(@event.tag_list).to eq []
    end

    it "should just cache tagging if it is a new record" do
      expect(@event).to_not receive :save
      expect(@event).to_not receive :tag_with
      expect(@event).to be_new_record
      @event.tag_list = @tags
      expect(@event.tag_list.to_s).to eq @tags
    end

    it "should use tags with punctuation" do
      tags = [".net", "foo-bar"]
      @event.tag_list = tags.join(", ")
      @event.save

      @event.reload
      expect(@event.tags.map(&:name).sort).to eq tags.sort
    end

    it "should not interpret numeric tags as IDs" do
      tag = "123"
      @event.tag_list = tag
      @event.save

      @event.reload
      expect(@event.tags.first.name).to eq "123"
    end

    it "should return a collection of events for a given tag" do
      @event.tag_list = @tags
      @event.save
      expect(Event.tagged_with('tags')).to eq [@event]
    end
  end

  describe "when parsing" do

    before do
      @basic_hcal = read_sample('hcal_basic.xml')
      @basic_venue = mock_model(Venue, :title => 'Argent Hotel, San Francisco, CA', :full_address => '50 3rd St, San Francisco, CA 94103')
      @basic_event = Event.new(
        :title => 'Web 2.0 Conference',
        :url => 'http://www.web2con.com/',
        :start_time => Time.zone.parse('2013-04-05'),
        :end_time => nil,
        :venue => @basic_venue)
    end

    it "should parse an AbstractEvent into an Event" do
      event = Event.new(:title => "EventTitle",
                        :description => "EventDescription",
                        :start_time => Time.zone.parse("2008-05-20"),
                        :end_time => Time.zone.parse("2008-05-22"))
      expect(Event).to receive(:new).and_return(event)

      abstract_event = AbstractEvent.new(
        :title => "EventTitle",
        :description => "EventDescription",
        :start_time => Time.zone.parse("2008-05-20"),
        :end_time => Time.zone.parse("2008-05-22"),
      )

      expect(Event.from_abstract_event(abstract_event)).to eq event
    end

    it "should parse an Event into an hCalendar" do
      actual_hcal = @basic_event.to_hcal
      pattern = Regexp.new(@basic_hcal.gsub(/\s+/, '\s+')) # Ignore spacing changes
      expect(actual_hcal).to match pattern
    end

    it "should parse an Event into an iCalendar" do
      actual_ical = @basic_event.to_ical

      abstract_events = SourceParser.to_abstract_events(:content => actual_ical, :skip_old => false)

      expect(abstract_events.size).to eq 1
      abstract_event = abstract_events.first
      expect(abstract_event.title).to eq @basic_event.title
      expect(abstract_event.url).to eq @basic_event.url
      expect(abstract_event.description).to be_nil

      expect(abstract_event.abstract_location.title).to match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
    end

    it "should parse an Event into an iCalendar without a URL and generate it" do
      generated_url = "http://foo.bar/"
      @basic_event.url = nil
      actual_ical = @basic_event.to_ical(:url_helper => lambda{|event| generated_url})

      abstract_events = SourceParser.to_abstract_events(:content => actual_ical, :skip_old => false)

      expect(abstract_events.size).to eq 1
      abstract_event = abstract_events.first
      expect(abstract_event.title).to eq @basic_event.title
      expect(abstract_event.url).to eq @basic_event.url
      expect(abstract_event.description).to match /Imported from: #{generated_url}/

      expect(abstract_event.abstract_location.title).to match "#{@basic_event.venue.title}: #{@basic_event.venue.full_address}"
    end

    it "should handle ambiguous times when creating iCalendar due to dst switchover period" do
      # See config/initializers/timezone.rb for more details
      site = create(:site, timezone: 'America/Los_Angeles')
      event = create(:event, created_at: '2016-11-06T01:32:54-0700')
      expect { event.to_ical }.to_not raise_error
    end
  end

  describe "when finding duplicates" do
    it "should find all events with duplicate titles" do
      expect(Event).to receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title )")
      Event.find_duplicates_by(:title)
    end

    it "should find all events with duplicate titles and urls" do
      expect(Event).to receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url )")
      Event.find_duplicates_by([:title,:url])
    end
  end

  describe "when finding duplicates by type" do
    def assert_default_find_duplicates_by_type(type)
      expect(Event).to receive(:future).and_return 42
      expect(Event.find_duplicates_by_type(type)).to eq({ [] => 42 })
    end

    it "should find all future events if called with nil" do
      assert_default_find_duplicates_by_type(nil)
    end

    it "should find all future events if called with empty string" do
      assert_default_find_duplicates_by_type('')
    end

    it "should find all future events if called with 'na'" do
      assert_default_find_duplicates_by_type('na')
    end

    def assert_specific_find_by_duplicates_by(type, queried)
      expect(Event).to receive(:find_duplicates_by).with(queried, {:grouped => true, :where => anything()})
      Event.find_duplicates_by_type(type)
    end

    it "should find events with all duplicate fields if called with 'all'" do
      assert_specific_find_by_duplicates_by('all', :all)
    end

    it "should find events with any duplicate fields if called with 'any'" do
      assert_specific_find_by_duplicates_by('any', :any)
    end

    it "should find events with duplicate titles if called with 'title'" do
      assert_specific_find_by_duplicates_by('title', ['title'])
    end
  end

  describe "when processing date" do
    before do
      @event = Event.new(:title => "MyEvent")
    end

    it "should fail to validate if start time is nil" do
      @event.start_time = nil
      expect(@event).to_not be_valid
      expect(@event).to have(1).error_on(:start_time)
    end

    it "should fail to validate if start time is blank" do
      @event.start_time = ""
      expect(@event).to_not be_valid
      expect(@event).to have(1).error_on(:start_time)
    end

    it "should fail to validate if end_time is earlier than start time " do
      @event.start_time = now
      @event.end_time = @event.start_time - 2.hours
      expect(@event.save).to be false
      expect(@event).to have(1).error_on(:end_time)
    end

  end

  describe "#time_for" do
    before do
      @date = "2009-01-02"
      @time = "03:45"
      @date_time = "#{@date} #{@time}"
      @value = Time.zone.parse(@date_time)
    end

    it "should return nil for a NilClass" do
      expect(Event.time_for(nil)).to be_nil
    end

    it "should return time for a String" do
      expect(Event.time_for(@date_time)).to eq @value
    end

    it "should return time for an Array of Strings" do
      expect(Event.time_for([@date, @time])).to eq @value
    end

    it "should return time for a DateTime" do
      expect(Event.time_for(@value)).to eq @value
    end

    it "should return exception for an invalid date expressed as a String" do
      expect { Event.time_for("0/0/0") }.to raise_error ArgumentError
    end

    it "should raise exception for an invalid type" do
      expect { Event.time_for(Event) }.to raise_error TypeError
    end
  end

  describe "#set_time_on" do
    it "should clear with nil" do
      expect(Event.new(:start_time => nil).start_time).to be_nil
    end

    it "should set from date String" do
      event = Event.new(:start_time => today.to_date.to_s(:db))
      expect(event.start_time).to be_a_kind_of ActiveSupport::TimeWithZone
      expect(event.start_time).to eq today
    end

    it "should set from date-time String" do
      event = Event.new(:start_time => today.localtime.to_s(:db))
      expect(event.start_time).to be_a_kind_of ActiveSupport::TimeWithZone
      expect(event.start_time).to eq today
    end

    it "should set from Date" do
      event = Event.new(:start_time => today.to_date)
      expect(event.start_time).to be_a_kind_of ActiveSupport::TimeWithZone
      expect(event.start_time).to eq today
    end

    it "should set from DateTime" do
      event = Event.new(:start_time => today.to_datetime)
      expect(event.start_time).to be_a_kind_of ActiveSupport::TimeWithZone
      expect(event.start_time).to eq today
    end

    it "should set from TimeWithZone" do
      event = Event.new(:start_time => Time.zone.now.midnight)
      expect(event.start_time).to be_a_kind_of ActiveSupport::TimeWithZone
      expect(event.start_time).to eq today
    end

    it "should set from Time" do
      time = today
      event = Event.new(:start_time => time)
      expect(event.start_time).to be_a_kind_of ActiveSupport::TimeWithZone
      expect(event.start_time).to eq time
    end

    it "should flag an invalid time" do
      event = build(:event)
      event.start_time = "1/0"
      expect(event.errors[:start_time]).to be_present
    end
  end

  describe "#save", :focus => true do
    context "creating an event" do
      context "with an associated source" do
        let(:source) { create(:source, :w_topics_types) }
        let(:event) { build(:event, :source => source) }

        it "associates source topics with event" do
          event.save!
          expect(event.topic_ids).to include(*source.topic_ids)
        end

        it "associates source types with event" do
          event.save!
          expect(event.type_ids).to include(*source.type_ids)
        end
      end
    end
  end

  describe "when finding by dates" do

    before do
      @today_midnight = today
      @yesterday = @today_midnight.yesterday
      @tomorrow = @today_midnight.tomorrow

      @this_venue = Venue.create!(:title => "This venue")

      @started_before_today_and_ends_after_today = Event.create!(
        :title => "Event in progress",
        :start_time => @yesterday,
        :end_time => @tomorrow,
        :venue_id => @this_venue.id)

      @started_midnight_and_continuing_after = Event.create!(
        :title => "Midnight start",
        :start_time => @today_midnight,
        :end_time => @tomorrow,
        :venue_id => @this_venue.id)

      @started_and_ended_yesterday = Event.create!(
        :title => "Yesterday start",
        :start_time => @yesterday,
        :end_time => @yesterday.end_of_day,
        :venue_id => @this_venue.id)

      @started_today_and_no_end_time = Event.create!(
        :title => "nil end time",
        :start_time => @today_midnight,
        :end_time => nil,
        :venue_id => @this_venue.id)

      @starts_and_ends_tomorrow = Event.create!(
        :title => "starts and ends tomorrow",
        :start_time => @tomorrow,
        :end_time => @tomorrow.end_of_day,
        :venue_id => @this_venue.id)

      @starts_after_tomorrow = Event.create!(
        :title => "Starting after tomorrow",
        :start_time => @tomorrow + 1.day,
        :venue_id => @this_venue.id)

      @started_before_today_and_ends_at_midnight = Event.create!(
        :title => "Midnight end",
        :start_time => @yesterday,
        :end_time => @today_midnight,
        :venue_id => @this_venue.id)

      @future_events_for_this_venue = @this_venue.events.future
    end

    describe "for overview" do
      # TODO:  consider writing the following specs as view specs
      # either in addition to, or instead of, model specs

      before do
        @overview = Event.select_for_overview
      end

      describe "events today" do
        it "should include events that started before today and end after today" do
          expect(@overview[:today]).to include @started_before_today_and_ends_after_today
        end

        it "should include events that started earlier today" do
          expect(@overview[:today]).to include @started_midnight_and_continuing_after
        end

        it "should not include events that ended before today" do
          expect(@overview[:today]).to_not include @started_and_ended_yesterday
        end

        it "should not include events that start tomorrow" do
          expect(@overview[:today]).to_not include @starts_and_ends_tomorrow
        end

        it "should not include events that ended at midnight today" do
          expect(@overview[:today]).to_not include @started_before_today_and_ends_at_midnight
        end
      end

      describe "events tomorrow" do
        it "should not include events that start after tomorrow" do
          expect(@overview[:tomorrow]).to_not include @starts_after_tomorrow
        end
      end

      describe "determining if we should show the more link" do
        it "should provide :more item if there are events past the future cutoff" do
          event = create(:event, start_time: 3.weeks.from_now)
          expect(Event.select_for_overview[:more]).to eq event
        end

        it "should set :more item if there are no events past the future cutoff" do
          event = create(:event, start_time: 3.weeks.from_now)
          expect(Event.select_for_overview[:more?]).to be_blank
        end
      end
    end

    describe "for future events" do
      before do
        @future_events = Event.future
      end

      it "should include events that started earlier today" do
        expect(@future_events).to include @started_midnight_and_continuing_after
      end

      it "should include events with no end time that started today" do
        expect(@future_events).to include @started_today_and_no_end_time
      end

      it "should include events that started before today and ended after today" do
        events = Event.future
        expect(events).to include @started_before_today_and_ends_after_today
      end

      it "should include events with no end time that started today" do
        expect(@future_events).to include @started_today_and_no_end_time
      end

      it "should not include events that ended before today" do
        expect(@future_events).to_not include @started_and_ended_yesterday
      end
    end

    describe "for future events with venue" do
      before do
        @another_venue = Venue.create!(:title => "Another venue")

        @future_event_another_venue = Event.create!(
          :title => "Starting after tomorrow",
          :start_time => @tomorrow + 1.day,
          :venue_id => @another_venue.id)

        @future_event_no_venue = Event.create!(
          :title => "Starting after tomorrow",
          :start_time => @tomorrow + 1.day)
      end

      # TODO Consider moving these examples elsewhere because they don't appear to relate to this scope. This comment applies to the examples from here...
      it "should include events that started earlier today" do
        expect(@future_events_for_this_venue).to include @started_midnight_and_continuing_after
      end

      it "should include events with no end time that started today" do
        expect(@future_events_for_this_venue).to include @started_today_and_no_end_time
      end

      it "should include events that started before today and ended after today" do
        expect(@future_events_for_this_venue).to include @started_before_today_and_ends_after_today
      end

      it "should not include events that ended before today" do
        expect(@future_events_for_this_venue).to_not include @started_and_ended_yesterday
      end
      # TODO ...to here.

      it "should not include events for another venue" do
        expect(@future_events_for_this_venue).to_not include @future_event_another_venue
      end

      it "should not include events with no venue" do
        expect(@future_events_for_this_venue).to_not include @future_event_no_venue
      end
    end

    describe "for date range" do
      it "should include events that started earlier today" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        expect(events).to include @started_midnight_and_continuing_after
      end

      it "should include events that started before today and end after today" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        expect(events).to include @started_before_today_and_ends_after_today
      end

      it "should not include past events" do
        events = Event.within_dates(@today_midnight, @tomorrow)
        expect(events).to_not include @started_and_ended_yesterday
      end

      it "should exclude events that start after the end of the range" do
        events = Event.within_dates(@tomorrow, @tomorrow)
        expect(events).to_not include @started_today_and_no_end_time
      end
    end
  end

  describe "when searching" do
    it "should find events" do
      expect(Event).to receive(:search).and_return([])

      expect(Event.search("myquery")).to be_empty
    end

    it "should find events and group them" do
      current_event = mock_model(Event, :current? => true, :duplicate_of_id => nil)
      past_event = mock_model(Event, :current? => false, :duplicate_of_id => nil)
      expect(Event).to receive(:search).and_return([current_event, past_event])

      expect(Event.search_keywords_grouped_by_currentness("myquery")).to eq({
        :current => [current_event],
        :past    => [past_event],
      })
    end

    it "should find events" do
      event_Z = Event.new(:title => "Zipadeedoodah", :start_time => (now + 1.week))
      event_A = Event.new(:title => "Antidisestablishmentarism", :start_time => (now + 2.weeks))
      event_O = Event.new(:title => "Ooooooo! Oooooooooooooo!", :start_time => (now + 3.weeks))
      event_o = Event.new(:title => "ommmmmmmmmmm...", :start_time => (now + 4.weeks))

      expect(Event).to receive(:search).and_return([event_A, event_Z, event_O, event_o])

      expect(Event.search_keywords_grouped_by_currentness("myquery", :order => 'name')).to eq({
        :current => [event_A, event_Z, event_O, event_o],
        :past => []
      })
    end
  end

  describe "when associating with venues" do
    before do
      @event = create(:event)
      @venue = create(:venue)
    end

    it "should not change a venue to a nil venue" do
      expect(@event.associate_with_venue(nil)).to be_nil
    end

    it "should associate a venue if one wasn't set before" do
      expect(@event.associate_with_venue(@venue)).to eq @venue
    end

    it "should change an existing venue to a different one" do
      @event.venue = create(:venue, :duplicate_of => @venue)

      expect(@event.associate_with_venue(@venue)).to eq @venue
    end

    it "should clear an existing venue if given a nil venue" do
      @event.venue = @venue

      expect(@event.associate_with_venue(nil)).to be_nil
      expect(@event.venue).to be_nil
    end

    it "should associate venue by title" do
      expect(Venue).to receive(:find_or_initialize_by).and_return(@venue)

      expect(@event.associate_with_venue(@venue.title)).to eq @venue
    end

    it "should associate venue by id" do
      expect(@event.associate_with_venue(@venue.id)).to eq @venue
    end

    it "should raise an exception if associated with an unknown type" do
      expect { @event.associate_with_venue(double('SourceParser')) }.to raise_error TypeError
    end

    describe "and searching" do
      it "should find events" do
        event_A = Event.new(:title => "Zipadeedoodah", :start_time => (now + 1.week))
        event_o = Event.new(:title => "Antidisestablishmentarism", :start_time => (now + 2.weeks))
        event_O = Event.new(:title => "Ooooooo! Oooooooooooooo!", :start_time => (now + 3.weeks))
        event_Z = Event.new(:title => "ommmmmmmmmmm...", :start_time => (now + 4.weeks))

        event_A.venue = Venue.new(:title => "Acme Hotel")
        event_o.venue = Venue.new(:title => "opbmusic Studios")
        event_O.venue = Venue.new(:title => "Oz")
        event_Z.venue = Venue.new(:title => "Zippers and Things")

        expect(Event).to receive(:search).and_return([event_A, event_Z, event_O, event_o])

        expect(Event.search_keywords_grouped_by_currentness("myquery", :order => 'venue')).to eq({
          :current => [event_A, event_Z, event_O, event_o],
          :past => []
        })
      end
    end
  end

  describe "with finding duplicates" do
    it "should find all events with duplicate titles" do
      expect(Event).to receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title )")
      Event.find_duplicates_by(:title )
    end

    it "should find all events with duplicate titles and urls" do
      expect(Event).to receive(:find_by_sql).with("SELECT DISTINCT a.* from events a, events b WHERE a.id <> b.id AND ( a.title = b.title AND a.url = b.url )")
      Event.find_duplicates_by([:title,:url])
    end

    describe "with sample records" do
      before do
        @non_duplicate_event = create(:event)
        @duplicate_event = create(:duplicate_event)
        @events = [@non_duplicate_event, @duplicate_event]
      end

      it "should find all events that have not been marked as duplicate" do
        non_duplicates = Event.non_duplicates
        expect(non_duplicates).to include @non_duplicate_event
        expect(non_duplicates).to_not include @duplicate_event
      end

      it "should find all events that have been marked as duplicate" do
        duplicates = Event.marked_duplicates
        expect(duplicates).to include @duplicate_event
        expect(duplicates).to_not include @non_duplicate_event
      end
    end
  end

  describe "with finding duplicates (integration test)" do
    before do
      @event = create(:event)
    end

    # Find duplicates, create another event with the given attributes, and find duplicates again
    # TODO Refactor #find_duplicates_create_a_clone_and_find_again and its uses into something simpler, like #assert_duplicate_count.
    def find_duplicates_create_a_clone_and_find_again(find_duplicates_arguments, clone_attributes, create_class = Event)
      before_results = create_class.find_duplicates_by( find_duplicates_arguments)
      clone = create_class.create!(clone_attributes.except('id'))
      after_results = Event.find_duplicates_by(find_duplicates_arguments)
      [before_results.sort_by(&:created_at), after_results.sort_by(&:created_at)]
    end

    it "should find duplicate title by title" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:title, {:title => @event.title, :start_time => @event.start_time} )
      expect(post.size).to eq(pre.size + 2)
    end

    it "should find duplicate title by any" do
      # TODO figure out why the #find_duplicates_create_a_clone_and_find_again isn't giving expected results and a workaround was needed.
      #pre, post = find_duplicates_create_a_clone_and_find_again(:any, {:title => @event.title, :start_time => @event.start_time} )
      #expect(post.size).to eq(pre.size + 2)
      dup_title = Event.create!({:title => @event.title, :start_time => @event.start_time + 1.minute})
      expect(Event.find_duplicates_by(:any)).to include dup_title
    end

    it "should not find duplicate title by url" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:url, {:title => @event.title, :start_time => @event.start_time} )
      expect(post.size).to eq pre.size
    end

    it "should find complete duplicates by all" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:all, @event.attributes)
      expect(post.size).to eq(pre.size + 2)
    end

    it "should not find incomplete duplicates by all" do
      pre, post = find_duplicates_create_a_clone_and_find_again(:all, @event.attributes.merge(:title => "SpaceCube", :start_time => @event.start_time ))
      expect(post.size).to eq pre.size
    end

    it "should find duplicate for matching multiple fields" do
      pre, post = find_duplicates_create_a_clone_and_find_again([:title, :start_time], {:title => @event.title, :start_time => @event.start_time })
      expect(post.size).to eq(pre.size + 2)
    end

    it "should not find duplicates for mismatching multiple fields" do
      pre, post = find_duplicates_create_a_clone_and_find_again([:title, :start_time], {:title => "SpaceCube", :start_time => @event.start_time })
      expect(post.size).to eq pre.size
    end
  end

  describe "when squashing duplicates (integration test)" do
    before do
      @event = create(:event)
    end

    it "should consolidate associations, and merge tags" do
      @event.tag_list = %w[first second] # master event contains one duplicate tag, and one unique tag

      clone = Event.create!(@event.attributes.except('id'))
      clone.tag_list.replace %w[second third] # duplicate event also contains one duplicate tag, and one unique tag
      clone.save!
      clone.reload
      expect(clone).to_not be_duplicate

      Event.squash(:master => @event, :duplicates => clone)
      expect(@event.tag_list.to_a.sort).to eq %w[first second third] # master now contains all three tags
      expect(clone.duplicate_of).to eq @event
    end
  end

  describe "when checking for squashing" do
    before do
      @today  = today
      @master = Event.create!(:title => "Master",    :start_time => @today)
      @slave1 = Event.create!(:title => "1st slave", :start_time => @today, :duplicate_of_id => @master.id)
      @slave2 = Event.create!(:title => "2nd slave", :start_time => @today, :duplicate_of_id => @slave1.id)
      @orphan = Event.create!(:title => "orphan",    :start_time => @today, :duplicate_of_id => 999999)
    end

    it "should recognize a master" do
      expect(@master).to be_a_master
    end

    it "should recognize a slave" do
      expect(@slave1).to be_a_slave
    end

    it "should not think that a slave is a master" do
      expect(@slave2).to_not be_a_master
    end

    it "should not think that a master is a slave" do
      expect(@master).to_not be_a_slave
    end

    it "should return the progenitor of a child" do
      expect(@slave1.progenitor).to eq @master
    end

    it "should return the progenitor of a grandchild" do
      expect(@slave2.progenitor).to eq @master
    end

    it "should return a master as its own progenitor" do
      expect(@master.progenitor).to eq @master
    end

    it "should return a marked duplicate as progenitor if it is orphaned"  do
      expect(@orphan.progenitor).to eq @orphan
    end

    it "should return the progenitor if an imported event has an exact duplicate" do
      @abstract_event = AbstractEvent.new
      @abstract_event.title = @slave2.title
      @abstract_event.start_time = @slave2.start_time.to_s

      expect(Event.from_abstract_event(@abstract_event)).to eq @master
    end

    it "should raise a DuplicateCheckingError if duplicate_of loop" do
      @master.duplicate_of = @slave2
      expect { @master.save! }.to raise_error DuplicateCheckingError
    end
  end

  describe "when versioning" do
    it "should have versions" do
      expect(Event.new.versions).to eq []
    end

    it "should create a new version after updating" do
      event = Event.create!(:title => "Event title", :start_time => Time.zone.parse('2008.04.12'))
      expect(event.versions.count).to eq 1

      event.title = "New Title"
      event.save!
      expect(event.versions.count).to eq 2
    end
  end

  describe "when normalizing line-endings in the description" do
    before do
      @event = Event.new
    end

    it "should not molest contents without carriage-returns" do
      @event.description         = "foo\nbar"
      expect(@event.description).to eq "foo\nbar"
    end

    it "should replace CRLF with LF" do
      @event.description         = "foo\r\nbar"
      expect(@event.description).to eq "foo\nbar"
    end

    it "should replace stand-alone CR with LF" do
      @event.description         = "foo\rbar"
      expect(@event.description).to eq "foo\nbar"
    end
  end

  describe "when cloning" do
    let :original do
      build(:event,
        :id => 42,
        :start_time => Time.zone.parse("2008-01-19 10:00 PST"),
        :end_time => Time.zone.parse("2008-01-19 17:00 PST"),
        :tag_list => "foo, bar, baz",
        :venue_details => "Details")
    end

    subject do
      original.to_clone
    end

    its(:new_record?) { should be true }

    its(:id) { should be_nil }

    its(:start_time) { should eq today + original.start_time.hour.hours }

    its(:end_time)   { should eq today + original.end_time.hour.hours }

    its(:tag_list) { should eq original.tag_list }

    %w[title description url venue_id venue_details].each do |field|
      its(field) { should eq original[field] }
    end
  end

  describe "when converting to iCal" do
    def ical_roundtrip(events, opts = {})
      parsed_events = RiCal.parse_string(Event.to_ical(events, opts)).first.events
      if events.is_a?(Event)
        parsed_events.first
      else
        parsed_events
      end
    end

    it "should produce parsable iCal output" do
      expect { ical_roundtrip( build(:event) ) }.to_not raise_error
    end

    it "should represent an event without an end time as a 1-hour block" do
      event = build(:event, :start_time => now, :end_time => nil)

      rt = ical_roundtrip(event)
      expect(rt.dtend - rt.dtstart).to eq 1.hour
    end

    it "should set the appropriate end time if one is given" do
      event = build(:event, :start_time => now, :end_time => now + 2.hours)

      rt = ical_roundtrip(event)
      expect(rt.dtend - rt.dtstart).to eq 2.hours
    end

    describe "when comparing Event's attributes to its iCalendar output" do
      let(:event) { build(:event, :id => 123, :created_at => now) }
      let(:ical) { ical_roundtrip(event) }

      { :summary => :title,
        :created => :created_at,
        :last_modified => :updated_at,
        :description => :description,
        :url => :url,
        :dtstart => :start_time,
        :dtstamp => :created_at
      }.each do |ical_attribute, model_attribute|
        it "should map the Event's #{model_attribute} attribute to '#{ical_attribute}' in the iCalendar output" do
          model_value = event.send(model_attribute)
          ical_value = ical.send(ical_attribute)

          case model_value
          when ActiveSupport::TimeWithZone
            # Compare raw time because one is using local time zone, while other is using UTC time.
            expect(model_value.to_i).to eq ical_value.to_i
          else
            expect(model_value).to eq ical_value
          end
        end
      end
    end

    it "should call the URL helper to generate a UID" do
      event = build(:event)
      expect(ical_roundtrip(event, :url_helper => lambda {|e| "UID'D!" }).uid).to eq "UID'D!"
    end

    it "should strip HTML from the description" do
      event = create(:event, :description => "<blink>OMFG HTML IS TEH AWESOME</blink>")
      expect(ical_roundtrip(event).description).to_not include "<blink>"
    end

    it "should include tags in the description" do
      event = build(:event)
      event.tag_list = "tags, folksonomy, categorization"
      expect(ical_roundtrip(event).description).to include event.tag_list.to_s
    end

    it "should leave URL blank if no URL is provided" do
      event = build(:event, :url => nil)
      expect(ical_roundtrip(event).url).to be_nil
    end

    it "should have Source URL if URL helper is given)" do
      event = build(:event)
      expect(ical_roundtrip(event, :url_helper => lambda{|e| "FAKE"} ).description).to match /FAKE/
    end

    it "should create multi-day entries for multi-day events" do
      time = Time.zone.now
      event = build(:event, :start_time => time, :end_time => time + 4.days)
      parsed_event = ical_roundtrip( event )

      start_time = Date.today
      expect(parsed_event.dtstart).to eq start_time
      expect(parsed_event.dtend).to eq(start_time + 5.days)
    end

    describe "sequence" do
      def event_to_ical(event)
        return RiCal.parse_string(Event.to_ical([event])).first.events.first
      end

      it "should set an initial sequence on a new event" do
        event = create(:event)
        ical = event_to_ical(event)
        expect(ical.sequence).to eq 1
      end

      it "should increment the sequence if it is updated" do
        event = create(:event)
        event.update_attribute(:title, "Update 1")
        ical = event_to_ical(event)
        expect(ical.sequence).to eq 2
      end
    end

    describe "- the headers" do
      let(:event) { build(:event) }
      subject(:ical) { event.to_ical }

      it "should include the calendar name" do
        expect(ical).to match /\sX-WR-CALNAME:#{event.site.name}\s/
      end

      it "should include the method" do
        expect(ical).to match /\sMETHOD:PUBLISH\s/
      end

      it "should include the scale" do
        expect(ical).to match /\sCALSCALE:Gregorian\s/i
      end
    end

  end

  describe "sorting labels" do
    it "should have sorting labels" do
      expect(Event::SORTING_LABELS).to be_a_kind_of Hash
    end

    it "should display human-friendly label for a known value" do
      expect(Event::sorting_label_for('name')).to eq 'Event Name'
    end

    it "should display a default label" do
      expect(Event::sorting_label_for(nil)).to eq 'Relevance'
    end

    it "should display a different default label when searching by tag" do
      expect(Event::sorting_label_for(nil, true)).to eq 'Date'
    end
  end

end
