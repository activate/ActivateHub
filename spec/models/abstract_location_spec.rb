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
  it { should validate_presence_of(:title) }

  #---[ Instance Methods ]--------------------------------------------------

  describe "#tags" do
    it "should be an empty array by default" do
      AbstractLocation.new.tags.should eq([])
    end
  end

  describe "#save_invalid!" do
    subject(:abstract_location) { build(:abstract_location, :invalid) }

    it "should persist to the database" do
      expect { abstract_location.save_invalid! } \
        .to change { AbstractLocation.count }.by(1)
    end

    it "should flag it as being invalid" do
      abstract_location.save_invalid!
      abstract_location.result.should eq 'invalid'
    end
  end

  #-------------------------------------------------------------------------

end
