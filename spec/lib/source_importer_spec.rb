require 'spec_helper'

describe SourceImporter do
  let(:source) { build_stubbed(:source) }
  let(:range_start) { Time.zone.now + 1.hour }
  let(:importer) { SourceImporter.new(source, :range_start => range_start) }

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

  describe "#original_events" do
    let(:range_start) { Time.zone.now + 1.day }

    it "returns only events associated with source" do
      create_list(:event, 2, :future, :source => source)
      create_list(:event, 1, :future) # not associated
      importer.original_events.should have(2).items
    end

    it "returns only events gteq to our :range_start" do
      create(:event, :source => source, :start_time => Time.zone.now)
      create(:event, :source => source, :start_time => range_start - 1.second)
      create(:event, :source => source, :start_time => range_start)
      importer.original_events.should have(1).item
    end
  end

  describe "#fetch_upstream" do
    it "should try to fetch abstract events from SourceParser" do
      SourceParser.should_receive(:to_abstract_events) do |options|
        options[:url].should eq source.url
        options[:source].should eq source
      end.and_return([])

      importer.fetch_upstream
    end

    it "should filter out abstract events not in our date range" do
      SourceParser.stub(:to_abstract_events => [
        build_stubbed(:abstract_event, :start_time => Time.zone.now),
        build_stubbed(:abstract_event, :start_time => range_start - 1.second),
        build_stubbed(:abstract_event, :start_time => range_start),
      ])

      importer.fetch_upstream
      importer.abstract_events.should have(1).item
    end
  end

end
