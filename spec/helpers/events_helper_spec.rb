require 'spec_helper'
include EventsHelper

RSpec.describe EventsHelper, type: :helper do
  describe "#events_sort_label" do
    it "should return nil without arguments" do
      expect(helper.events_sort_label(nil)).to be_nil
    end

    it "should return string for a string key" do
      expect(helper.events_sort_label("score")).to match(/ by .+#{Event::SORTING_LABELS['score']}.+/)
    end

    it "should return string for a symbol key" do
      expect(helper.events_sort_label(:score)).to match(/ by .+#{Event::SORTING_LABELS['score']}.+/)
    end

    it "should return special string when using a tag" do
      assign :tag, ActsAsTaggableOn::Tag.new
      expect(helper.events_sort_label(nil)).to match(/ by .+#{Event::SORTING_LABELS['default']}.+/)
    end
  end

  describe "google_event_export_link" do
    def escape(string)
      return Regexp.escape(CGI.escape(string))
    end

    shared_context "exported event setup" do
      before do
        @venue = Venue.create!(:title => "My venue", :address => "1930 SW 4th Ave, Portland, Oregon 97201")
        @event = Event.create!(:title => "My event", :start_time => Time.zone.now - 1.hour, :end_time => Time.zone.now, :venue => @venue, :description => event_description)
        @export = helper.google_event_export_link(@event)
      end
    end

    shared_examples_for "exported event" do
      it "should have title" do
        expect(@export).to match /\&text=#{escape(@event.title)}/
      end

      it "should have time range" do
        expect(@export).to match /\&dates=#{helper.format_google_timespan(@event)}/
      end

      it "should have venue title" do
        expect(@export).to match /\&location=#{escape(@event.venue.title)}/
      end

      it "should have venue address" do
        expect(@export).to match /\&location=.+?#{escape(@event.venue.geocode_address)}/
      end
    end

    describe "an event's text doesn't need truncation" do
      let(:event_description) { "My event description." }
      include_context "exported event setup"

      it_should_behave_like "exported event"

      it "should have a complete event description" do
        expect(@export).to match /\&details=.*#{escape(event_description)}/
      end
    end

    describe "an event's text needs truncation" do
      let(:event_description) { "My event description. " * 100 }
      include_context "exported event setup"

      it_should_behave_like "exported event"

      it "should have a truncated event description" do
        expect(@export).to match /\&details=.*#{escape(event_description[0..100])}/
      end

      it "should have a truncated URL" do
        expect(@export.size).to be < event_description.size
      end
    end
  end

  describe "#google_events_subscription_link" do
    def method(*args)
      helper.google_events_subscription_link(*args)
    end

    it "should fail if given unknown options" do
      expect { method(:omg => :kittens) }.to raise_error ArgumentError
    end

    it "should generate a default link" do
      expect(method).to eq "http://www.google.com/calendar/render?cid=http%3A%2F%2Ftest.host%2Fevents.ics"
    end

    it "should generate a search link" do
      expect(method(:query => "my query")).to eq "http://www.google.com/calendar/render?cid=http%3A%2F%2Ftest.host%2Fevents%2Fsearch.ics%3Fquery%3Dmy%2Bquery"
    end

    it "should generate a tag link" do
      expect(method(:tag => "mytag")).to eq "http://www.google.com/calendar/render?cid=http%3A%2F%2Ftest.host%2Fevents%2Fsearch.ics%3Ftag%3Dmytag"
    end
  end

  describe "#icalendar_feed_link" do
    def method(*args)
      helper.icalendar_feed_link(*args)
    end

    it "should fail if given unknown options" do
      expect { method(:omg => :kittens) }.to raise_error ArgumentError
    end

    it "should generate a default link" do
      expect(method).to eq "webcal://test.host/events.ics"
    end

    it "should generate a search link" do
      expect(method(:query => "my query")).to eq "webcal://test.host/events/search.ics?query=my+query"
    end

    it "should generate a tag link" do
      expect(method(:tag => "mytag")).to eq "webcal://test.host/events/search.ics?tag=mytag"
    end
  end

  describe "#icalendar_export_link" do
    def method(*args)
      helper.icalendar_export_link(*args)
    end

    it "should fail if given unknown options" do
      expect { method(:omg => :kittens) }.to raise_error ArgumentError
    end

    it "should generate a default link" do
      expect(method).to eq "http://test.host/events.ics"
    end

    it "should generate a search link" do
      expect(method(:query => "my query")).to eq "http://test.host/events/search.ics?query=my+query"
    end

    it "should generate a tag link" do
      expect(method(:tag => "mytag")).to eq "http://test.host/events/search.ics?tag=mytag"
    end
  end

  describe "#atom_feed_link" do
    def method(*args)
      helper.atom_feed_link(*args)
    end

    it "should fail if given unknown options" do
      expect { method(:omg => :kittens) }.to raise_error ArgumentError
    end

    it "should generate a default link" do
      expect(method).to eq "http://test.host/events.atom"
    end

    it "should generate a search link" do
      expect(method(:query => "my query")).to eq "http://test.host/events/search.atom?query=my+query"
    end

    it "should generate a tag link" do
      expect(method(:tag => "mytag")).to eq "http://test.host/events/search.atom?tag=mytag"
    end
  end

  describe "format_google_timespan" do
    # TODO
  end

end
