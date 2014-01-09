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
    let(:abstract_events) { build_list(:abstract_event, 3, :future) }
    before(:each) {
      abstract_events.each {|ae| ae.abstract_location = build(:abstract_location) }
      SourceParser.stub(:to_abstract_events => abstract_events)
    }

    it "fetches upstream events if not already fetched" do
      importer.should_receive(:fetch_upstream).once.and_call_original
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
  end

end
