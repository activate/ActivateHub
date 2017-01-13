require 'rails_helper'

# Tests defined in mix-in examples should only verify that the mix-in
# was included in the +described_class+ and that it was properly set up.
#
# If you want to add tests for the mix-in's behavior itself, see the
# *_spec.rb version of this file instead.
#
RSpec.shared_examples_for Rebaseable do
  describe "mixing instance methods into model" do
    subject { described_class.new }
    it { should respond_to :rebase_changed_attributes! }
  end

  describe "rebasing two objects" do
    it "should not raise an error" do
      # just want to exercise the method once for anything catastrophic
      obj1, obj2 = 2.times.map { described_class.new }
      expect { obj1.rebase_changed_attributes!(obj2) }.to_not raise_error
    end
  end

end
