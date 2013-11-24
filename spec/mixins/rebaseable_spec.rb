require 'spec_helper'
require 'mixins/rebaseable_examples'

describe Rebaseable do
  subject(:car) do
    Class.new(TestClasses::DirtyModel) do
      include Rebaseable
      define_attributes :color, :doors, :model, :price
    end
  end

  it_should_behave_like Rebaseable do
    let(:described_class) { car }
  end

  describe "#rebase_changed_attributes" do
    let(:parent) { car.new(:color => 'black', :doors => 0) }
    let(:child) { car.new(:color => 'white') }

    it "returns a copy of the child after #rebase_changed_attributes!" do
      result = child.rebase_changed_attributes(parent)
      result.color.should eq 'white'
      result.doors.should eq 0
    end

    it "doesn't change original child attributes" do
      expect { child.rebase_changed_attributes(parent) } \
        .to_not change { child.attributes }
    end
  end

  describe "#rebase_changed_attributes!" do
    let(:parent) { car.new(:color => 'black', :doors => 4, :model => 'ZZ-T00') }
    let(:child) { car.new(:color => 'white', :doors => 2, :price => 8_000) }

    it "returns the receiver/self" do
      child.rebase_changed_attributes!(parent).should eq child
    end

    it "copies attributes from the parent" do
      # ...that haven't been flagged as changed in the child
      child.rebase_changed_attributes!(parent)
      child.model.should eq 'ZZ-T00'
    end

    it "only keeps child attributes that have been flagged as changed" do
      child.changed_attributes.delete('doors')
      child.rebase_changed_attributes!(parent)
      child.doors.should eq 4       # unchanged
      child.color.should eq 'white' # changed
      child.price.should eq 8_000   # changed
    end

    it "preserves nil value changes in child" do
      # new model objects start with nil so we'd be going from nil to nil,
      # force model to think the original value was non-nil
      child.changed_attributes['doors'] = 1

      child.doors = nil
      child.rebase_changed_attributes!(parent)
      child.doors.should eq nil
    end

    it "preserves false value changes in child" do
      child.doors = false
      child.rebase_changed_attributes!(parent)
      child.doors.should be_false
    end

    it "changed attribute info reflects changes between parent and child" do
      # updating a value to its original value should not show in changes
      child.doors = 4 # parent.doors is already 4

      child.rebase_changed_attributes!(parent)
      child.changed.sort.should eq %w(color price)
    end
  end

end
