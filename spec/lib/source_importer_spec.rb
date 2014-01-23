require 'spec_helper'

describe SourceImporter do
  let(:source) { build_stubbed(:source) }
  let(:range_start) { Time.zone.now + 1.hour }
  let(:range_end) { Time.zone.now + 1.year }

  let(:importer) do
    SourceImporter.new(source,
      :range_start => range_start,
      :range_end   => range_end
    )
  end

  describe "#range_start" do
    it "can be provided on initialization" do
      expected = Time.zone.now + 1.day
      importer = SourceImporter.new(source, :range_start => expected)
      importer.range_start.should eq expected
    end

    it "should default to one hour from now" do
      expected = Time.zone.now + 1.hour
      SourceImporter.new(source).range_start.should eq expected
    end
  end

  describe "#range_end" do
    it "can be provided on initialization" do
      expected = Time.zone.now + 3.years
      importer = SourceImporter.new(source, :range_end => expected)
      importer.range_end.should eq expected
    end

    it "should default to one year from now" do
      expected = Time.zone.now + 1.year
      SourceImporter.new(source).range_end.should eq expected
    end
  end

  describe "#original_events" do
    let(:range_start) { Time.zone.now + 1.day }

    it "returns only events associated with source" do
      create_list(:event, 2, :future, :source => source)
      create_list(:event, 1, :future) # not associated
      importer.original_events.should have(2).items
    end

    it "returns only events with a start time gteq to our :range_start" do
      create(:event, :source => source, :start_time => Time.zone.now)          # excluded
      create(:event, :source => source, :start_time => range_start - 1.second) # excluded
      create(:event, :source => source, :start_time => range_start)            # included
      importer.original_events.should have(1).item
    end

    it "returns only events with a start time lt our :range_end" do
      create(:event, :source => source, :start_time => range_end + 1.year)   # excluded
      create(:event, :source => source, :start_time => range_end - 1.second) # included
      create(:event, :source => source, :start_time => range_end)            # excluded
      importer.original_events.should have(1).item
    end
  end

  describe "#fetch_upstream" do
    it "should try to fetch abstract events from SourceParser" do
      SourceParser.should_receive(:to_abstract_events) do |options|
        options[:url].should eq source.url
      end.and_return([])

      importer.fetch_upstream
    end

    it "should filter out abstract events not in our date range" do
      SourceParser.stub(:to_abstract_events => [
        build_stubbed(:abstract_event, :start_time => Time.zone.now),          # excluded
        build_stubbed(:abstract_event, :start_time => range_start - 1.second), # excluded
        build_stubbed(:abstract_event, :start_time => range_start),            # included
        build_stubbed(:abstract_event, :start_time => range_end - 1.second),   # included
        build_stubbed(:abstract_event, :start_time => range_end),              # excluded
      ])

      importer.fetch_upstream
      importer.abstract_events.should have(2).items
    end

    it "should extract abstract locations from their abstract events" do
      SourceParser.stub(:to_abstract_events => [
        build_stubbed(:abstract_event, :w_location),
        build_stubbed(:abstract_event),
        build_stubbed(:abstract_event, :w_location),
      ])

      importer.fetch_upstream
      importer.abstract_locations.should have(2).items
    end

    it "should associate source with abstract events" do
      SourceParser.stub(:to_abstract_events => [build_stubbed(:abstract_event)])
      importer.fetch_upstream
      importer.abstract_events.first.source.should eq source
    end

    it "should associate source with abstract locations" do
      SourceParser.stub(:to_abstract_events => [build_stubbed(:abstract_event,
        :abstract_location => build_stubbed(:abstract_location)
      )])
      importer.fetch_upstream
      importer.abstract_locations.first.source.should eq source
    end
  end

  describe "#import!" do
    let(:abstract_locations) { build_list(:abstract_location, 3) }
    let(:abstract_events) { build_list(:abstract_event, 3, :future) }
    before(:each) {
      importer.stub(:fetch_upstream) do
        importer.instance_variable_set(:@abstract_locations, abstract_locations)
        importer.instance_variable_set(:@abstract_events, abstract_events)
        true
      end
    }

    it "should return true" do
      importer.import!.should be_true
    end

    it "fetches upstream events if not already fetched" do
      # "and_return(importer.fetch_upstream)" forces stubbed method to be called.
      # "and_call_original" calls the original implemention, even when stubbed :(
      importer.should_receive(:fetch_upstream).and_return(importer.fetch_upstream)
      importer.import!
    end

    it "doesn't fetch upstream events if already fetched" do
      importer.fetch_upstream
      importer.should_receive(:fetch_upstream).never
      importer.import!
    end

    it "imports valid abstract locations" do
      expect { importer.import! }.to change { AbstractLocation.count }.by(3)
    end

    it "imports valid abstract events" do
      expect { importer.import! }.to change { AbstractEvent.count }.by(3)
    end

    context "with invalid locations" do
      before(:each) do
        abstract_events.last.abstract_location = build(:abstract_location, :invalid)
      end

      it "persists invalid abstract locations (for eventual triage)" do
        expect { importer.import! }.to change { AbstractLocation.invalid.count }.by(1)
      end
    end

    context "with invalid events" do
      let(:abstract_events) { build_list(:abstract_event, 2, :invalid) }

      it "persists invalid abstract events (for eventual triage)" do
        expect { importer.import! }.to change { AbstractEvent.invalid.count }.by(2)
      end
    end

    context "with a location that raises an error" do
      before(:each) do
        location = build(:abstract_location)
        location.stub(:import!).and_raise('unhandled error')
        abstract_events.last.abstract_location = location
      end

      it "propagates the error" do
        expect { importer.import! }.to raise_error
      end
    end

    context "with a event that raises an error" do
      before(:each) do
        abstract_events.last.stub(:import!).and_raise('unhandled error')
      end

      it "propagates the error" do
        expect { importer.import! }.to raise_error
      end
    end

    context "with duplicate unchanged locations" do
      let(:abstract_locations) do
        locations = build_list(:abstract_location, 3)
        locations.first.import!

        # should result in 2 created and 7 unchanged after import
        result = 3.times.flat_map { locations.map(&:dup) }
      end

      it "filters out unchanged locations that match others in same import" do
        importer.import!
        importer.abstract_locations.map(&:result).should eq [
          'unchanged', 'created', 'created'
        ]
      end
    end
  end

  describe "#summary" do
    before(:each) {
      importer.stub(:abstract_locations => [
        *build_stubbed_list(:abstract_location, 1, :result => 'created'),
        *build_stubbed_list(:abstract_location, 2, :result => 'unchanged'),
        build_stubbed(:abstract_location, :result => 'invalid'),
        build_stubbed(:abstract_location, :result => 'updated'),
      ])

      importer.stub(:abstract_events => [
        *build_stubbed_list(:abstract_event, 2, :result => 'created'),
        *build_stubbed_list(:abstract_event, 3, :result => 'unchanged'),
        build_stubbed(:abstract_event, :result => 'invalid'),
        build_stubbed(:abstract_event, :result => 'updated'),
      ])
    }

    it "reports total number of events found upstream" do
      importer.summary.should match /7 event/i
    end

    it "reports net increase of 1 venue" do
      importer.summary.should match /Venues:\s*\+1/i
    end

    it "reports correct number of abstract locations" do
      venue_summary = importer.summary[/^Venues:\s*[+-].*?\n(?:\s+[^s].*\n)+/]
      venue_summary.should match /Invalid:\s*1/i
      venue_summary.should match /Created:\s*1/i
      venue_summary.should match /Updated:\s*1/i
      venue_summary.should match /Unchanged:\s*2/i
    end

    it "reports correct number of abstract events" do
      event_summary = importer.summary[/^Events:\s*[+-].*?\n(?:\s+[^\s].*\n)+/]
      event_summary.should match /Invalid:\s*1/i
      event_summary.should match /Created:\s*2/i
      event_summary.should match /Updated:\s*1/i
      event_summary.should match /Unchanged:\s*3/i
    end

    it "reports net increase of 2 events" do
      importer.summary.should match /Events:\s*\+2/i
    end
  end

end
