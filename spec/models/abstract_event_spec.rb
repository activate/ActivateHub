require 'spec_helper'
require 'mixins/dirty_attr_accessor_examples'
require 'mixins/rebaseable_examples'

RSpec.describe AbstractEvent, type: :model do
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

  it_should_behave_like DirtyAttrAccessor
  it_should_behave_like Rebaseable

  #---[ Scopes ]------------------------------------------------------------

  describe "(scopes)" do
    describe "::invalid" do
      it "should return only invalid abstract events" do
        create(:abstract_event)
        build_list(:abstract_event, 2, :invalid).each(&:save_invalid!)
        AbstractEvent.invalid.size.should eq 2
      end
    end
  end

  #---[ ActiveRecord Callbacks ]--------------------------------------------

  describe ":after_find callback" do
    let(:abstract_event) { build(:abstract_event) }

    it "populates the organization_id attribute from source" do
      abstract_event.source = create(:source, :w_organization)
      abstract_event.import!

      expected = abstract_event.source.organization_id
      AbstractEvent.find(abstract_event.id).organization_id.should eq expected
    end

    it "populates the venue_id attribute from abstract_location" do
      abstract_event.abstract_location = build(:abstract_location)

      abstract_event.abstract_location.import!
      abstract_event.import!

      expected = abstract_event.abstract_location.venue_id
      AbstractEvent.find(abstract_event.id).venue_id.should eq expected
    end
  end

  #--- [ Constants ]--------------------------------------------------------

  describe "::EVENT_ATTRIBUTES" do
    it "includes expected attributes" do
      AbstractEvent::EVENT_ATTRIBUTES.should include(
        :url, :title, :end_time, :start_time, :description, :venue_id,
        :organization_id
      )
    end

    it ":end_time comes before :start_time, otherwise might get auto-gen" do
      start_time_idx = AbstractEvent::EVENT_ATTRIBUTES.index(:start_time)
      end_time_idx = AbstractEvent::EVENT_ATTRIBUTES.index(:end_time)
      end_time_idx.should be < start_time_idx
    end
  end

  #---[ Custom Attributes ]-------------------------------------------------
  # non-persistent attributes and the overrides required to behave correctly

  describe ":organization_id" do
    it "is included in attributes list" do
      abstract_event.attributes.keys.should include('organization_id')
    end

    it "supports dirty/change tracking" do
      abstract_event.organization_id = 12345
      abstract_event.organization_id_changed?.should be true
      abstract_event.changed_attributes.should include('organization_id')
    end
  end

  describe ":venue_id" do
    it "is included in attributes list" do
      abstract_event.attributes.keys.should include('venue_id')
    end

    it "supports dirty/change tracking" do
      abstract_event.venue_id = 54321
      abstract_event.venue_id_changed?.should be true
      abstract_event.changed_attributes.should include('venue_id')
    end
  end

  #---[ Instance Methods ]--------------------------------------------------

  describe "#abstract_location=" do
    it "sets the :venue_title attribute to abstract location's title" do
      al = build_stubbed(:abstract_location, :source => source, :title => 'The Bog')
      abstract_event.abstract_location = al
      abstract_event.venue_title.should eq 'The Bog'
    end

    it "sets the :venue_id attribute to abstract location's venue_id" do
      al = build_stubbed(:abstract_location, :source => source, :venue_id => 864531)
      abstract_event.abstract_location = al
      abstract_event.venue_id.should eq 864531
    end
  end

  describe "#event_attributes_changed" do
    subject(:abstract_event) { AbstractEvent.new } # has no changes

    it "is empty when nothing changes" do
      abstract_event.event_attributes_changed.should eq []
    end

    it "is empty when a non event attribute changes" do
      abstract_event.raw_event = 'Kanon!'
      abstract_event.event_attributes_changed.should eq []
    end

    exclude = [:organization_id, :venue_id, :start_time, :end_time]
    (AbstractEvent::EVENT_ATTRIBUTES-exclude).each do |attribute_name|
      it "includes attribute name when #{attribute_name} changes" do
        abstract_event.send("#{attribute_name}=", 'foo')
        abstract_event.event_attributes_changed.should eq [attribute_name]
      end

      it "includes attribute name when start_time changes" do
        abstract_event.start_time = 27.days.from_now
        abstract_event.event_attributes_changed.should eq [:start_time]
      end

      it "includes attribute name when end_time changes" do
        abstract_event.end_time = 28.days.from_now
        abstract_event.event_attributes_changed.should eq [:end_time]
      end

      it "includes attribute name when venue_id changes" do
        abstract_event.abstract_location = build_stubbed(:abstract_location, :venue_id => 947343)
        abstract_event.event_attributes_changed.should eq [:venue_id]
      end

      it "includes attribute name when organization_id changes" do
        abstract_event.source = build_stubbed(:source, :organization_id => 474747)
        abstract_event.event_attributes_changed.should eq [:organization_id]
      end
    end
  end

  describe "#event_attributes_changed?" do
    it "is true when #event_attributes_changed is not empty" do
      abstract_event.stub(:event_attributes_changed => [:title, :description])
      abstract_event.event_attributes_changed?.should be true
    end

    it "is false when #event_attributes_changed is empty" do
      abstract_event.stub(:event_attributes_changed => [])
      abstract_event.event_attributes_changed?.should be false
    end
  end

  describe "#import!" do
    subject(:abstract_event) { build(:abstract_event) }

    context "with an existing abstract event" do
      let!(:existing) do
        abstract_event.dup.tap(&:import!) # make attributes identical by default
      end

      before(:each) do
        AbstractEvent.any_instance.stub(:find_existing => existing)
      end

      it "should attempt a rebase" do
        abstract_event.should_receive(:rebase_changed_attributes!).with(existing)
        abstract_event.import!
      end

      context "abstract event has changes" do
        before(:each) { abstract_event.description = "Synchronized Coffee Grinding" }

        it "saves a new copy of the abstract event" do
          expect { abstract_event.import! } \
            .to change { AbstractEvent.count }.by(1)
        end

        it "returns 'updated' as its result" do
          expect(abstract_event.import!).to eq 'updated'
        end

        it "set the :result attribute to 'updated'" do
          abstract_event.tap(&:import!).reload # ensure it's persisted
          abstract_event.result.should eq 'updated'
        end

        context "has an associated event" do
          it "populates and saves the event" do
            expect {
              abstract_event.should_receive(:populate_event).and_call_original
              abstract_event.import!
            }.to change { existing.event.reload.description }
          end
        end

        context "has no associated event (was destroyed)" do
          before(:each) { existing.event.destroy }

          it "does not try to create a new event" do
            expect { abstract_event.import! }.to_not change { Event.count }
          end
        end

        context "has invalid attributes" do
          before(:each) { abstract_event.title = '' }

          it "raises an ActiveRecord::RecordInvalid exception" do
            expect { abstract_event.import! } \
              .to raise_error ActiveRecord::RecordInvalid
          end
        end
      end

      context "abstract event has no changes" do
        it "does not save a new copy of the abstract event" do
          expect { abstract_event.import! } \
            .to_not change { AbstractEvent.count }
        end

        it "returns 'unchanged' as its result" do
          expect(abstract_event.import!).to eq 'unchanged'
        end

        it "sets the :result attribute to 'unchanged'" do
          abstract_event.import!
          abstract_event.result.should eq 'unchanged'
        end

        it "sets the id to the existing abstract event" do
          expect { abstract_event.import! } \
            .to change { abstract_event.id }.from(nil).to(existing.id)
        end
      end
    end

    context "without an existing abstract event" do
      it "saves a new copy of the abstract event" do
        expect { abstract_event.import! } \
          .to change { AbstractEvent.count }.by(1)
      end

      it "should not rebase the event" do
        abstract_event.should_not_receive :rebase_changed_attributes!
        abstract_event.import!
      end

      it "returns 'created' as its result" do
        expect(abstract_event.import!).to eq 'created'
      end

      it "set the :result attribute to 'created'" do
        abstract_event.tap(&:import!).reload # ensure it's persisted
        abstract_event.result.should eq 'created'
      end

      context "has invalid attributes" do
        before(:each) { abstract_event.title = '' }

        it "raises an ActiveRecord::RecordInvalid exception" do
          expect { abstract_event.import! } \
            .to raise_error ActiveRecord::RecordInvalid
        end
      end
    end

    context "with an abstract_location" do
      let(:abstract_location) { build(:abstract_location) }
      before(:each) { abstract_event.abstract_location = abstract_location }

      it "imports the abstract location if not imported" do
        abstract_location.should_receive(:import!).and_call_original
        abstract_event.import!
      end

      it "doesn't import abstract location if already imported" do
        abstract_location.import!
        abstract_location.should_receive(:import!).never
        abstract_event.import!
      end

      it "associates the venue with the created event" do
        abstract_event.import!
        abstract_event.event.venue.should_not be_nil # sanity check
        abstract_event.event.venue_id.should eq abstract_location.venue_id
      end

      context "abstract_location is invalid" do
        let(:abstract_location) { build(:abstract_location, :invalid) }

        it "saves the the location as invalid" do
          abstract_event.import!
          abstract_event.abstract_location.result.should eq 'invalid'
        end

        it "doesn't prevent importing the event" do
          abstract_event.import!
          abstract_event.result.should eq 'created'
        end
      end

      context "abstract_location has 'unchanged' result" do
        # 'unchanged' abstract locations have their :id attribute set so we can
        # find the persisted copy if needed, but are still considered a new
        # record to ActiveRecord, and will try create a new record on 'save'
        before(:each) do
          abstract_location.dup.import!
          abstract_location.import!
          abstract_location.result.should eq 'unchanged'
        end

        it "should not try to re-save abstract location" do
          abstract_location.should_not receive(:save)
          abstract_event.import!
        end
      end

      context "abstract_location raises an error" do
        before(:each) do
          abstract_location.stub(:import!).and_raise('unhandled_error')
        end

        it "doesn't save abstract event" do
          expect { abstract_event.import! rescue nil } \
            .to_not change { AbstractEvent.count }
        end

        it "propagates the error" do
          expect { abstract_event.import! }.to raise_error
        end
      end
    end
  end

  describe "#populate_event" do
    let(:abstract_event) { build(:abstract_event, :w_event_attributes) }
    let(:event_attributes) { AbstractEvent::EVENT_ATTRIBUTES.map(&:to_s) }

    it "should return the event object" do
      event = abstract_event.populate_event
      event.should eq abstract_event.event
    end

    context "no associated event" do
      it "should initialize a new event object" do
        abstract_event.populate_event
        abstract_event.event.should_not be_nil
      end

      it "should not save the event" do
        expect { abstract_event.populate_event }.to_not change { Event.count }
      end

      it "should populate event with event attributes" do
        # needed for organization_id and venue_id
        abstract_event.source = build(:source, :w_organization)
        abstract_event.abstract_location = build(:abstract_location).tap(&:import!)

        abstract_event.populate_event
        changed = abstract_event.event.changed
        changed.should include(*event_attributes)
      end

      it "should associate event with abstract event's source" do
        abstract_event.populate_event
        abstract_event.event.source.should eq abstract_event.source
      end
    end

    context "with an associated event" do
      let!(:event) do
        # we sort of cheat here, but it should be valid unless other tests fail
        event = abstract_event.populate_event
        event.changed_attributes.clear
        event
      end

      it "should not save the event" do
        event.should_not_receive :save
        event.should_not_receive :save!
        abstract_event.populate_event
      end

      context "without any changed attributes" do
        # event is unchanged by default for these tests

        it "should not change the event" do
          event = abstract_event.populate_event
          event.changed?.should be false
        end
      end

      context "with changed attributes" do
        it "changes event attributes that match expected '_was' value" do
          # *_was is defined in ActiveModel::Dirty and represents value before
          # applying local changes (in our case, parent value before rebasing)
          abstract_event.description = event.description
          abstract_event.changed_attributes.delete('description') # reset
          abstract_event.description = 'We upgraded our snow shoes to moon boots'

          abstract_event.populate_event
          event.description.should eq 'We upgraded our snow shoes to moon boots'
          event.changed.should include('description')
        end

        it "doesn't change attributes changed outside of abstract event" do
          # simulate an event change outside of an abstract event, because
          # people like to program computers to change URLs to random things
          event.url = 'http://get-your-talkie-talking-toaster.now/'
          event.changed_attributes.clear

          # whereas people like to translate their urls into gibberish
          abstract_event.url = 'youtu.be/LRq_SAuQDec' # "Howdy doodly doo!"

          abstract_event.populate_event
          event.changed.should_not include('url')
        end
      end
    end

    context "with an associated non-master event" do
      let!(:event) do
        abstract_event.import!
        event = abstract_event.event
        event.duplicate_of = event.dup.tap(&:save!)
        event.tap(&:save!)
      end

      let(:progenitor) { event.progenitor }

      it "should apply changes to progenitor" do
        abstract_event.description = "Who needs shoes when there's no gravity?"

        abstract_event.populate_event
        progenitor.description.should eq "Who needs shoes when there's no gravity?"
        progenitor.changed.should include('description')
      end
    end

    context "with a destroyed event" do
      let!(:event) do
        abstract_event.import!
        event = abstract_event.event.tap(&:destroy)
        abstract_event.reload # reloads :event association
        event
      end

      before(:each) do
        # give the abstract event some changes to propagate
        abstract_event.description = "I think I found a black hole."
      end

      it "should not raise an error" do
        expect { abstract_event.populate_event }.to_not raise_error
      end

      it "should not create a new event" do
        expect { abstract_event.populate_event }.to_not change { Event.count }
      end
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
      ae_attrs = { :source => source, :external_id => 'x', :event => create(:event) }
      create(:abstract_event, ae_attrs)

      # matcher value changed, but shares venue w/ a event that should match
      expected = create(:abstract_event, ae_attrs.merge(:external_id => 'y'))

      create(:abstract_event, :source => source) # filler, won't match

      ae = build(:abstract_event, :source => source, :external_id => 'x')
      ae.find_existing.should eq expected
    end
  end

  describe "#rebase_changed_attributes!" do
    # start with something that would be considered identical
    let!(:existing) { abstract_event.dup }

    context "when both abstract events have same values" do
      it "should not report having any event field changes" do
        abstract_event.rebase_changed_attributes!(existing)
        abstract_event.event_attributes_changed?.should be false
      end
    end

    context "when non-event fields have changed" do
      before(:each) { abstract_event.raw_event = 'xyz12493875' }

      it "should not have any event field changes" do
        abstract_event.rebase_changed_attributes!(existing)
        abstract_event.event_attributes_changed?.should be false
      end
    end

    context "when event fields have changed" do
      before(:each) { abstract_event.title = 'Sandwich Making Contest' }

      it "should report having event field changes" do
        abstract_event.rebase_changed_attributes!(existing)
        abstract_event.event_attributes_changed?.should be true
      end
    end
  end

  describe "#save_invalid!" do
    subject(:abstract_event) { build(:abstract_event, :invalid) }

    it "should persist to the database" do
      expect { abstract_event.save_invalid! } \
        .to change { AbstractEvent.count }.by(1)
    end

    it "should flag it as being invalid" do
      abstract_event.save_invalid!
      abstract_event.result.should eq 'invalid'
    end
  end

  #-------------------------------------------------------------------------

end
