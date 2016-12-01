require 'spec_helper'

RSpec.describe Type, type: :model do
  describe "in general" do
	  before(:each) do
	    @type = Type.new(:name => "My Type")
	  end
	  specify {expect(@type).to be_valid}
  end

  # describe "when relating types and events" do
  #   before(:each) do
  #     @type = Type.new(:name => "protest")
  #     @event = Event.new(:title => "Event title")
  #   end

  #   it "should find "


  describe "when creating nameless types" do
	  before(:each) do
	    @type = Type.new()
	  end
	  specify {expect(@type).to_not be_valid}
  end
end


