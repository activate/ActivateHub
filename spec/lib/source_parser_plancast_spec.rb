require 'spec_helper'

RSpec.describe SourceParser::Plancast do

  before(:each) do
    content = read_sample('plancast.json')
    expect(HTTParty).to receive(:get).and_return(JSON.parse(content))
    @events = SourceParser::Plancast.to_abstract_events(:url => 'http://plancast.com/p/3cos/indiewebcamp')
    @event = @events.first
  end

  it "should find one event" do
    expect(@events.size).to eq 1
  end

  it "should set event details" do
    expect(@event.title).to eq "IndieWebCamp"
    expect(@event.start_time).to eq Time.zone.parse("Sat, 25 Jun 2011 00:00:00 PDT -07:00")
  end

  it "should tag Plancast events with automagic machine tags" do
    expect(@event.tags).to eq ["plancast:plan=3cos"]
  end

  it "should populate a venue when structured data is provided" do
    expect(@event.abstract_location.title).to eq "Urban Airship"
    expect(@event.abstract_location.address).to eq "334 Northwest 11th Avenue, Portland, Oregon, United States"
    expect(@event.abstract_location.tags).to eq ["plancast:place=1520153"]
  end

end
