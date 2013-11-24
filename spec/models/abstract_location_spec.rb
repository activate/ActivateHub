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

  it_should_behave_like Rebaseable

  #---[ Scopes ]------------------------------------------------------------

  describe "(scopes)" do
    describe "::invalid" do
      it "should return only invalid abstract location" do
        create(:abstract_location)
        build_list(:abstract_location, 2, :invalid).each(&:save_invalid!)
        AbstractLocation.invalid.size.should eq 2
      end
    end
  end

  #---[ Instance Methods ]--------------------------------------------------

  describe "#find_existing" do
    let(:source) { create(:source) }
    before(:each) { create(:abstract_location, :source => source) } # ensure multiple ALs

    it "only searches within the current source" do
      existing = create(:abstract_location, :external_id => 'Rx448354')
      aloc = build(:abstract_location, :external_id => 'Rx448354')
      aloc.find_existing.should be_nil
    end

    it "matches using :external_id attribute" do
      existing = create(:abstract_location, :source => source, :external_id => 'ZF')
      aloc = build(:abstract_location, :source => source, :external_id => 'ZF')
      aloc.find_existing.should eq existing
    end

    it "doesn't attempt any matchers that have blank attributes" do
      create(:abstract_location, :source => source, :external_id => '')
      aloc = build(:abstract_location, :source => source, :external_id => '')
      aloc.find_existing.should_not eq abstract_location
    end

    it "matches using :title attribute" do
      existing = create(:abstract_location, :source => source,
        :title => "The mind of Schrodinger's cat",
      )

      aloc = build(:abstract_location, :source => source,
        :title => "The mind of Schrodinger's cat",
      )

      aloc.find_existing.should eq existing
    end

    it "matches using address fields when :street_address is present" do
      existing = create(:abstract_location, :w_address, :source => source,
        :street_address => 'Anywhere',
      )

      aloc = build(:abstract_location, :source => source,
        :address        => existing.address,
        :street_address => existing.street_address,
        :locality       => existing.locality,
        :region         => existing.region,
        :postal_code    => existing.postal_code,
        # inc. country is overkill as almost guaranteed uniq without
      )

      aloc.find_existing.should eq existing
    end

    it "doesn't match using address fields when :street_address is blank" do
      existing = create(:abstract_location, :w_address, :source => source,
        :street_address => '',
      )

      aloc = build(:abstract_location, :source => source,
        :address        => existing.address,
        :street_address => existing.street_address,
        :locality       => existing.locality,
        :region         => existing.region,
        :postal_code    => existing.postal_code,
        # inc. country is overkill as almost guaranteed uniq without
      )

      aloc.find_existing.should be_nil
    end

    it "returns the most recently created match" do
      alocs = create_list(:abstract_location, 3, :source => source, :external_id => 'k')
      aloc = build(:abstract_location, :source => source, :external_id => 'k')
      aloc.find_existing.should eq alocs.last
    end
  end

  describe "#rebase_changed_attributes!" do
    # start with something that would be considered identical
    let!(:existing) { abstract_location.dup }

    context "when both abstract locations have same values" do
      it "should not report having any venue field changes" do
        abstract_location.rebase_changed_attributes!(existing)
        abstract_location.venue_attributes_changed?.should be_false
      end
    end

    context "when fields have changed" do
      before(:each) { abstract_location.raw_venue = 'asdf83fkkhefg' }

      it "should retain that field's original value" do
        abstract_location.rebase_changed_attributes!(existing)
        abstract_location.raw_venue.should eq 'asdf83fkkhefg'
      end

      it "should record that field as having changed" do
        abstract_location.rebase_changed_attributes!(existing)
        abstract_location.raw_venue_changed?.should be_true
      end

      it "should only retain fields that were actually changed" do
        existing.venue_id = 999_999
        abstract_location.rebase_changed_attributes!(existing)
        abstract_location.venue_id.should eq 999_999
      end
    end

    context "when only non-venue fields have changed" do
      before(:each) { abstract_location.raw_venue = 'asdf83fkkhefg' }

      it "should not have any venue field changes" do
        abstract_location.rebase_changed_attributes!(existing)
        abstract_location.venue_attributes_changed?.should be_false
      end
    end

    context "when venue fields have changed" do
      before(:each) { abstract_location.title = '1970s Telco Switchboard Room' }

      it "should report having venue field changes" do
        abstract_location.rebase_changed_attributes!(existing)
        abstract_location.venue_attributes_changed?.should be_true
      end
    end
  end

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

  describe "#venue_attributes_changed" do
    subject(:abstract_location) { AbstractLocation.new } # has no changes

    it "is empty when nothing changes" do
      abstract_location.venue_attributes_changed.should eq []
    end

    it "is empty when a non venue attribute changes" do
      abstract_location.raw_venue = 'Where spiders the weave fairy floss'
      abstract_location.venue_attributes_changed.should eq []
    end

    AbstractLocation::VENUE_ATTRIBUTES.each do |attribute_name|
      it "includes attribute name  when #{attribute_name} changes" do
        abstract_location.send("#{attribute_name}=", :foo)
        abstract_location.venue_attributes_changed.should eq [attribute_name]
      end
    end
  end

  describe "#venue_attributes_changed?" do
    it "is true when #venue_attributes_change is not empty" do
      abstract_location.stub(:venue_attributes_changed => [:title, :description])
      abstract_location.venue_attributes_changed?.should be_true
    end

    it "is false when #venue_attributes_changed is empty" do
      abstract_location.stub(:venue_attributes_changed => [])
      abstract_location.venue_attributes_changed?.should be_false
    end
  end

  #-------------------------------------------------------------------------

end
