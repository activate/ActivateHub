require 'spec_helper'
require 'mixins/rebaseable_examples'

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

  describe "#import!" do
    subject(:abstract_location) { build(:abstract_location) }

    context "with an existing abstract location" do
      let(:existing) do
        abstract_location.dup # make attributes identical by default
      end

      before(:each) do
        AbstractLocation.any_instance.stub(:find_existing => existing)
      end

      it "should attempt a rebase" do
        abstract_location.should_receive(:rebase_changed_attributes!).with(existing)
        abstract_location.import!
      end

      context "abstract location has changes" do
        before(:each) { abstract_location.description = "Where capsaicin is king" }

        it "saves a new copy of the abstract location" do
          expect { abstract_location.import! } \
            .to change { AbstractLocation.count }.by(1)
        end

        it "returns 'updated' as its result" do
          expect(abstract_location.import!).to eq 'updated'
        end

        it "set the :result attribute to 'updated'" do
          abstract_location.tap(&:import!).reload # ensure it's persisted
          abstract_location.result.should eq 'updated'
        end

        context "has invalid attributes" do
          before(:each) { abstract_location.title = '' }

          it "raises an ActiveRecord::RecordInvalid exception" do
            expect { abstract_location.import! } \
              .to raise_error ActiveRecord::RecordInvalid
          end
        end
      end

      context "abstract location has no changes" do
        it "does not save a new copy of the abstract location" do
          expect { abstract_location.import! } \
            .to_not change { AbstractLocation.count }
        end

        it "returns 'unchanged' as its result" do
          expect(abstract_location.import!).to eq 'unchanged'
        end

        it "sets the :result attribute to 'unchanged'" do
          abstract_location.import!
          abstract_location.result.should eq 'unchanged'
        end
      end
    end

    context "without an existing abstract location" do
      it "saves a new copy of the abstract location" do
        expect { abstract_location.import! } \
          .to change { AbstractLocation.count }.by(1)
      end

      it "should not rebase the location" do
        abstract_location.should_not_receive :rebase_changed_attributes!
        abstract_location.import!
      end

      it "returns 'created' as its result" do
        expect(abstract_location.import!).to eq 'created'
      end

      it "set the :result attribute to 'created'" do
        abstract_location.tap(&:import!).reload # ensure it's persisted
        abstract_location.result.should eq 'created'
      end

      context "has invalid attributes" do
        before(:each) { abstract_location.title = '' }

        it "raises an ActiveRecord::RecordInvalid exception" do
          expect { abstract_location.import! } \
            .to raise_error ActiveRecord::RecordInvalid
        end
      end
    end
  end

  describe "#populate_venue" do
    let(:abstract_location) { build(:abstract_location, :w_venue_attributes) }
    let(:venue_attributes) { AbstractLocation::VENUE_ATTRIBUTES.map(&:to_s) }

    it "should return the venue object" do
      venue = abstract_location.populate_venue
      venue.should eq abstract_location.venue
    end

    context "no associated venue" do
      it "should initialize a new venue object" do
        abstract_location.populate_venue
        abstract_location.venue.should_not be_nil
      end

      it "should not save the venue" do
        expect { abstract_location.populate_venue } \
          .to_not change { Venue.count }
      end

      it "should populate venue with venue attributes" do
        abstract_location.populate_venue
        changed = abstract_location.venue.changed
        changed.should include(*venue_attributes)
      end

      it "should associate venue with abstract location's source" do
        abstract_location.populate_venue
        abstract_location.venue.source.should eq abstract_location.source
      end
    end

    context "with an associated venue" do
      let!(:venue) do
        # we sort of cheat here, but it should be valid unless other tests fail
        venue = abstract_location.populate_venue
        venue.changed_attributes.clear
        venue
      end

      it "should not save the venue" do
        venue.should_not_receive :save
        venue.should_not_receive :save!
        abstract_location.populate_venue
      end

      context "without any changed attributes" do
        # venue is unchanged by default for these tests

        it "should not change the venue" do
          venue = abstract_location.populate_venue
          venue.changed?.should be_false
        end
      end

      context "with changed attributes" do
        it "changes venue attributes that match expected '_was' value" do
          # *_was is defined in ActiveModel::Dirty and represents value before
          # applying local changes (in our case, parent value before rebasing)
          abstract_location.description = venue.description
          abstract_location.changed_attributes.delete('description') # reset
          abstract_location.description = 'Classified'

          abstract_location.populate_venue
          venue.description.should eq 'Classified'
          venue.changed.should include('description')
        end

        it "doesn't change attributes changed outside of abstract location" do
          # simulate a venue change outside of an abstract location, because
          # people like to program computers to change URLs to random things
          venue.url = 'http://if.charlie.brown.was.an.atheist/'
          venue.changed_attributes.clear

          # whereas people like to translate their urls into gibberish
          abstract_location.url = 'http://bit.ly/1hdhFhW' # yes, yes it does

          abstract_location.populate_venue
          venue.changed.should_not include('url')
        end
      end
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
    it "is true when #venue_attributes_changed is not empty" do
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
