require 'rails_helper'
require 'mixins/rebaseable_examples'

RSpec.describe AbstractLocation, type: :model do
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
        expect(AbstractLocation.invalid.size).to eq 2
      end
    end
  end

  #--- [ Constants ]--------------------------------------------------------

  describe "::VENUE_ATTRIBUTES" do
    it "includes expected attributes" do
      expect(AbstractLocation::VENUE_ATTRIBUTES).to include(
        :url, :title, :description, :address, :street_address, :locality, :region,
        :postal_code, :country, :latitude, :longitude, :email, :telephone
      )
    end
  end

  #---[ Instance Methods ]--------------------------------------------------

  describe "#find_existing" do
    let(:source) { create(:source) }
    before(:each) { create(:abstract_location, :source => source) } # ensure multiple ALs

    it "only searches within the current source" do
      existing = create(:abstract_location, :external_id => 'Rx448354')
      aloc = build(:abstract_location, :external_id => 'Rx448354')
      expect(aloc.find_existing).to be_nil
    end

    it "matches using :external_id attribute" do
      existing = create(:abstract_location, :source => source, :external_id => 'ZF')
      aloc = build(:abstract_location, :source => source, :external_id => 'ZF')
      expect(aloc.find_existing).to eq existing
    end

    it "doesn't attempt any matchers that have blank attributes" do
      create(:abstract_location, :source => source, :external_id => '')
      aloc = build(:abstract_location, :source => source, :external_id => '')
      expect(aloc.find_existing).to_not eq abstract_location
    end

    it "matches using :title attribute" do
      existing = create(:abstract_location, :source => source,
        :title => "The mind of Schrodinger's cat",
      )

      aloc = build(:abstract_location, :source => source,
        :title => "The mind of Schrodinger's cat",
      )

      expect(aloc.find_existing).to eq existing
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

      expect(aloc.find_existing).to eq existing
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

      expect(aloc.find_existing).to be_nil
    end

    it "returns the most recently created match" do
      al_attrs = { :source => source, :external_id => 'k', :venue => create(:venue) }
      create(:abstract_location, al_attrs)

      # matcher value changed, but shares venue w/ a location that should match
      expected = create(:abstract_location, al_attrs.merge(:external_id => 'd'))

      create(:abstract_location, :source => source) # filler, won't match

      aloc = build(:abstract_location, :source => source, :external_id => 'k')
      expect(aloc.find_existing).to eq expected
    end
  end

  describe "#import!" do
    subject(:abstract_location) { build(:abstract_location) }

    context "with an existing abstract location" do
      let!(:existing) do
        abstract_location.dup.tap(&:import!) # make attributes identical by default
      end

      before(:each) do
        allow_any_instance_of(AbstractLocation).to receive(:find_existing).and_return(existing)
      end

      it "should attempt a rebase" do
        expect(abstract_location).to receive(:rebase_changed_attributes!).with(existing)
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
          expect(abstract_location.result).to eq 'updated'
        end

        context "has an associated venue" do
          it "populates and saves the venue" do
            expect {
              expect(abstract_location).to receive(:populate_venue).and_call_original
              abstract_location.import!
            }.to change { existing.venue.reload.description }
          end
        end

        context "has no associated venue (was destroyed)" do
          before(:each) { existing.venue.destroy }

          it "does not try to create a new venue" do
            expect { abstract_location.import! }.to_not change { Venue.count }
          end
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
          expect(abstract_location.result).to eq 'unchanged'
        end

        it "sets the id to the existing abstract location" do
          expect { abstract_location.import! } \
            .to change { abstract_location.id }.from(nil).to(existing.id)
        end
      end
    end

    context "without an existing abstract location" do
      it "saves a new copy of the abstract location" do
        expect { abstract_location.import! } \
          .to change { AbstractLocation.count }.by(1)
      end

      it "should not rebase the location" do
        expect(abstract_location).to_not receive :rebase_changed_attributes!
        abstract_location.import!
      end

      it "returns 'created' as its result" do
        expect(abstract_location.import!).to eq 'created'
      end

      it "set the :result attribute to 'created'" do
        abstract_location.tap(&:import!).reload # ensure it's persisted
        expect(abstract_location.result).to eq 'created'
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
      expect(venue).to eq abstract_location.venue
    end

    context "no associated venue" do
      it "should initialize a new venue object" do
        abstract_location.populate_venue
        expect(abstract_location.venue).to_not be_nil
      end

      it "should not save the venue" do
        expect { abstract_location.populate_venue } \
          .to_not change { Venue.count }
      end

      it "should populate venue with venue attributes" do
        abstract_location.populate_venue
        changed = abstract_location.venue.changed
        expect(changed).to include(*venue_attributes)
      end

      it "should associate venue with abstract location's source" do
        abstract_location.populate_venue
        expect(abstract_location.venue.source).to eq abstract_location.source
      end
    end

    context "with an associated venue" do
      let!(:venue) do
        # we sort of cheat here, but it should be valid unless other tests fail
        venue = abstract_location.populate_venue
        venue.clear_changes_information
        venue
      end

      it "should not save the venue" do
        expect(venue).to_not receive :save
        expect(venue).to_not receive :save!
        abstract_location.populate_venue
      end

      context "without any changed attributes" do
        # venue is unchanged by default for these tests

        it "should not change the venue" do
          venue = abstract_location.populate_venue
          expect(venue.changed?).to be false
        end
      end

      context "with changed attributes" do
        it "changes venue attributes that match expected '_was' value" do
          # *_was is defined in ActiveModel::Dirty and represents value before
          # applying local changes (in our case, parent value before rebasing)
          abstract_location.description = venue.description
          abstract_location.clear_changes_information
          abstract_location.description = 'Classified'

          abstract_location.populate_venue
          expect(venue.description).to eq 'Classified'
          expect(venue.changed).to include('description')
        end

        it "doesn't change attributes changed outside of abstract location" do
          # simulate a venue change outside of an abstract location, because
          # people like to program computers to change URLs to random things
          venue.url = 'http://if.charlie.brown.was.an.atheist/'
          venue.clear_changes_information

          # whereas people like to translate their urls into gibberish
          abstract_location.url = 'http://bit.ly/1hdhFhW' # yes, yes it does

          abstract_location.populate_venue
          expect(venue.changed).to_not include('url')
        end
      end
    end

    context "with an associated non-master venue" do
      let!(:venue) do
        abstract_location.import!
        venue = abstract_location.venue
        venue.duplicate_of = venue.dup.tap(&:save!)
        venue.tap(&:save!)
      end

      let(:progenitor) { venue.progenitor }

      it "should apply changes to progenitor" do
        abstract_location.description = 'Description missing, reward offered!'

        abstract_location.populate_venue
        expect(progenitor.description).to eq 'Description missing, reward offered!'
        expect(progenitor.changed).to include('description')
      end
    end

    context "with a destroyed venue" do
      let!(:venue) do
        abstract_location.import!
        venue = abstract_location.venue.tap(&:destroy)
        abstract_location.reload # reloads :venue association
        venue
      end

      before(:each) do
        # give the abstract location some changes to propagate
        abstract_location.description = "The ground looks a bit fuzzy."
      end

      it "should not raise an error" do
        expect { abstract_location.populate_venue }.to_not raise_error
      end

      it "should not create a new venue" do
        expect { abstract_location.populate_venue }.to_not change { Venue.count }
      end
    end
  end

  describe "#rebase_changed_attributes!" do
    # start with something that would be considered identical
    let!(:existing) { abstract_location.dup }

    context "when both abstract locations have same values" do
      it "should not report having any venue field changes" do
        abstract_location.rebase_changed_attributes!(existing)
        expect(abstract_location.venue_attributes_changed?).to be false
      end
    end

    context "when only non-venue fields have changed" do
      before(:each) { abstract_location.raw_venue = 'asdf83fkkhefg' }

      it "should not have any venue field changes" do
        abstract_location.rebase_changed_attributes!(existing)
        expect(abstract_location.venue_attributes_changed?).to be false
      end
    end

    context "when venue fields have changed" do
      before(:each) { abstract_location.title = '1970s Telco Switchboard Room' }

      it "should report having venue field changes" do
        abstract_location.rebase_changed_attributes!(existing)
        expect(abstract_location.venue_attributes_changed?).to be true
      end
    end
  end

  describe "#tags" do
    it "should be an empty array by default" do
      expect(AbstractLocation.new.tags).to eq([])
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
      expect(abstract_location.result).to eq 'invalid'
    end
  end

  describe "#venue_attributes_changed" do
    subject(:abstract_location) { AbstractLocation.new } # has no changes

    it "is empty when nothing changes" do
      expect(abstract_location.venue_attributes_changed).to eq []
    end

    it "is empty when a non venue attribute changes" do
      abstract_location.raw_venue = 'Where spiders the weave fairy floss'
      expect(abstract_location.venue_attributes_changed).to eq []
    end

    AbstractLocation::VENUE_ATTRIBUTES.each do |attribute_name|
      it "includes attribute name  when #{attribute_name} changes" do
        abstract_location.send("#{attribute_name}=", :foo)
        expect(abstract_location.venue_attributes_changed).to eq [attribute_name]
      end
    end
  end

  describe "#venue_attributes_changed?" do
    it "is true when #venue_attributes_changed is not empty" do
      allow(abstract_location).to receive(:venue_attributes_changed).and_return([:title, :description])
      expect(abstract_location.venue_attributes_changed?).to be true
    end

    it "is false when #venue_attributes_changed is empty" do
      allow(abstract_location).to receive(:venue_attributes_changed).and_return([])
      expect(abstract_location.venue_attributes_changed?).to be false
    end
  end

  #-------------------------------------------------------------------------

end
