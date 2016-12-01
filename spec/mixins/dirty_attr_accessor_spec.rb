require 'spec_helper'
require 'mixins/dirty_attr_accessor_examples'

RSpec.describe DirtyAttrAccessor do
  subject(:boat_ride_model) do
    Class.new(TestClasses::DirtyModel) do
      define_attributes *[] # ^^^ don't emulate any ActiveRecord columns

      include DirtyAttrAccessor
      dirty_attr_accessor :top_speed, :llamas_sighted # everywhere a llama llama
    end
  end

  let(:boat_ride) { boat_ride_model.new }

  it_should_behave_like DirtyAttrAccessor do
    let(:described_class) { boat_ride_model }
  end

  describe "::dirty_attr_accessor" do
    it "sets up readers for all args" do
      boat_ride.should respond_to :top_speed
      boat_ride.should respond_to :llamas_sighted
    end

    it "sets up writer for all args" do
      boat_ride.should respond_to :top_speed=
      boat_ride.should respond_to :llamas_sighted=
    end
  end

  describe "#llamas_sighted (attr reader)" do
    it "returns the assigned value" do
      boat_ride.llamas_sighted = 6
      boat_ride.llamas_sighted.should eq 6
    end
  end

  describe "#llamas_sighted= (attr writer)" do
    it "adds the attribute to list of changed attributes" do
      boat_ride.llamas_sighted = 7_141_000_000
      boat_ride.changed_attributes.should include('llamas_sighted')
    end

    it "removes attr from changed attributes when orig value restored" do
      boat_ride.llamas_sighted = 47
      boat_ride.llamas_sighted = nil
      boat_ride.changed_attributes.should_not include('llamas_sighted')
    end
  end

  describe "#reset_llamas_sighted!" do # why would you ever want to unsee a llama? :(
    before(:each) do
      boat_ride.llamas_sighted = 324
      boat_ride.changed_attributes.clear
      boat_ride.llamas_sighted = 325 # dirty llamas
    end

    it "restores :llamas_sighted to orig value" do
      boat_ride.reset_llamas_sighted!
      boat_ride.llamas_sighted = 324
    end

    it "clears the changed flag" do
      boat_ride.reset_llamas_sighted!
      boat_ride.llamas_sighted_changed?.should be false
    end
  end

  it "#llamas_sighted_change should include old and new value" do
    expect { boat_ride.llamas_sighted = 99 }
      .to change { boat_ride.llamas_sighted_change }.from(nil).to([nil, 99])
  end

  it "#llamas_sighted_changed? should be true after change" do
    expect { boat_ride.llamas_sighted = 555 } \
      .to change { boat_ride.llamas_sighted_changed? }.from(false).to(true)
  end

  it "#llamas_sighted_will_change! set changed flag" do # llama sense is sensing
    expect { boat_ride.llamas_sighted_will_change! } \
      .to change { boat_ride.llamas_sighted_changed? }.from(false).to(true)
  end

  it "#llamas_sighted_was should return return original value" do
    boat_ride.llamas_sighted = 216
    boat_ride.changed_attributes.clear

    boat_ride.llamas_sighted = 40_124 # wat?
    boat_ride.llamas_sighted_was.should eq 216
  end

end
