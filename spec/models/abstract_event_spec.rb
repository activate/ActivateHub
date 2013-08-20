require 'spec_helper'

describe AbstractEvent do
  subject(:abstract_event) { build_stubbed(:abstract_event) }

  it { should be_valid }

  it { should belong_to(:site) }
  it { should belong_to(:source) }
  it { should belong_to(:event) }
  it { should belong_to(:abstract_location) }

  # sanity check attributes (not very BDD-style though)
  it { should serialize(:tags).as(Array) }

  it { should validate_presence_of(:site_id) }
  it { should validate_presence_of(:source_id) }


  #---[ Instance Methods ]--------------------------------------------------

  describe "#tags" do
    it "should be an empty array by default" do
      AbstractEvent.new.tags.should eq([])
    end
  end

  #-------------------------------------------------------------------------

end
