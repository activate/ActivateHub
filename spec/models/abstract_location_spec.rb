require 'spec_helper'

describe AbstractLocation do
  subject(:abstract_location) { build_stubbed(:abstract_location) }

  it { should be_valid }

  it { should belong_to(:site) }
  it { should belong_to(:source) }
  it { should belong_to(:venue) }
  it { should have_many(:abstract_events) }

  # sanity check attributes (not very BDD-style though)
  it { should serialize(:tags).as(Array) }

  it { should validate_presence_of(:site_id) }
  it { should validate_presence_of(:source_id) }


  #---[ Instance Methods ]--------------------------------------------------

  describe "#tags" do
    it "should be an empty array by default" do
      AbstractLocation.new.tags.should eq([])
    end
  end

  #-------------------------------------------------------------------------

end
