require 'spec_helper'

RSpec.describe "Event with default blacklist", type: :model do
  before(:each) do
    @event = Event.new(:title => "Title", :start_time => Time.zone.now)
  end

  it "should be valid when clean" do
    @event.should be_valid
  end

  it "should not be valid when it features blacklisted word" do
    @event.title = "Foo bar cialis"
    @event.should_not be_valid
  end
end

RSpec.describe "Event with custom blacklist", type: :model do
  class Event
    validates_blacklist_on :title, :patterns => [/Kltpzyxm/i]
  end

  before(:each) do
    @event = Event.new(:title => "Title", :start_time => Time.zone.now)
  end

  it "should be valid when clean" do
    @event.should be_valid
  end

  it "should not be valid when it features custom blacklisted word" do
    @event.title = "fooKLTPZYXMbar"
    @event.should_not be_valid
  end
end

RSpec.describe "Event created with custom blacklist file", type: :model do
  before(:each) do
    Event.should_receive(:_get_blacklist_patterns_from).with(nil).and_return([])
    Event.should_receive(:_get_blacklist_patterns_from).with("blacklist-local.txt").and_return([/Kltpzyxm/i])
    @event = Event.new(:title => "Title", :start_time => Time.zone.now)
  end

  it "should be valid when clean" do
    @event.should be_valid
  end

  it "should not be valid when it features custom blacklisted word" do
    @event.title = "fooKLTPZYXMbar"
    @event.should_not be_valid
  end
end
