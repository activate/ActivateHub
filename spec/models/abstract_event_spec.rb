require 'spec_helper'

describe AbstractEvent do
  subject(:abstract_event) { build_stubbed(:abstract_event, :source => source) }
  let(:source) { build_stubbed(:source) }

  it { should be_valid }

  it { should belong_to(:site) }
  it { should belong_to(:source) }
  it { should belong_to(:event) }
  it { should belong_to(:abstract_location) }

  # sanity check attributes (not very BDD-style though)
  it { should serialize(:tags).as(Array) }

  it { should validate_presence_of(:site_id) }
  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:start_time) }
  it { should validate_presence_of(:end_time) }

  #---[ Instance Methods ]--------------------------------------------------

  describe "#abstract_location=" do
    it "sets the :venue_title attribute to abstract location's title" do
      al = build_stubbed(:abstract_location, :source => source, :title => 'The Bog')
      abstract_event.abstract_location = al
      abstract_event.venue_title.should eq 'The Bog'
    end
  end

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
      create(:abstract_event, :source => source, :external_id => '')
      ae = build(:abstract_event, :source => source, :external_id => '')
      ae.find_existing.should_not eq abstract_event
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
