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

  describe "#find_existing" do
    let(:source) { create(:source) }
    before(:each) { create(:abstract_event, :source => source) } # ensure multiple AEs

    it "only searches within the current source" do
      existing = create(:abstract_event, :external_id => 'faraway')
      ae = build(:abstract_event, :external_id => 'faraway')
      ae.find_existing.should be_nil
    end

    it "matches using :external_id attribute" do
      existing = create(:abstract_event, :source => source, :external_id => 'FA')
      ae = build(:abstract_event, :source => source, :external_id => 'FA')
      ae.find_existing.should eq existing
    end

    it "doesn't attempt any matchers that have blank attributes" do
      create(:abstract_event, :source => source, :external_id => nil)
      create(:abstract_event, :source => source, :external_id => '')
      ae = build(:abstract_event, :source => source, :external_id => '')
      ae.find_existing.should be_nil
    end

    it "matches using :title and :start_time attributes" do
      existing = create(:abstract_event, :source => source,
        :title      => 'Pony Drag Racing XR',
        :start_time => Time.zone.now + 1.day,
      )

      ae = build(:abstract_event, :source => source,
        :title      => 'Pony Drag Racing XR',
        :start_time => Time.zone.now + 1.day,
      )

      ae.find_existing.should eq existing
    end

    it "matches using :venue_title and :start_time attributes" do
      existing = create(:abstract_event, :source => source,
        :venue_title => 'Airport Detention Cell',
        :start_time  => Time.zone.now + 1.day,
      )

      ae = build(:abstract_event, :source => source,
        :venue_title => 'Airport Detention Cell',
        :start_time  => Time.zone.now + 1.day,
      )

      ae.find_existing.should eq existing
    end

    it "returns the most recently created match" do
      aes = create_list(:abstract_event, 3, :source => source, :external_id => 'x')
      ae = build(:abstract_event, :source => source, :external_id => 'x')
      ae.find_existing.should eq aes.last
    end
  end

  #-------------------------------------------------------------------------

end
