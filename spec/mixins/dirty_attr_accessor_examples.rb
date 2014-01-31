require 'spec_helper'

# Tests defined in mix-in examples should only verify that the mix-in
# was included in the +described_class+ and that it was properly set up.
#
# If you want to add tests for the mix-in's behavior itself, see the
# *_spec.rb version of this file instead.
#
shared_examples_for DirtyAttrAccessor do
  describe "mixing class methods into model" do
    subject { described_class }
    it { should respond_to :dirty_attr_accessor }
  end

end
