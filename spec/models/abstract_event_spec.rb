require 'spec_helper'
require 'mixins/rebaseable_examples'

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

  #---[ Instance Methods ]--------------------------------------------------

  describe "#abstract_location=" do
    it "sets the :venue_title attribute to abstract location's title" do
      al = build_stubbed(:abstract_location, :source => source, :title => 'The Bog')
      abstract_event.abstract_location = al
      abstract_event.venue_title.should eq 'The Bog'
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

    AbstractEvent::EVENT_ATTRIBUTES.each do |attribute_name|
      it "includes attribute name  when #{attribute_name} changes" do
        abstract_event.send("#{attribute_name}=", :foo)
        abstract_event.event_attributes_changed.should eq [attribute_name]
      end
    end
  end

  describe "#event_attributes_changed?" do
    it "is true when #event_attributes_changed is not empty" do
      abstract_event.stub(:event_attributes_changed => [:title, :description])
      abstract_event.event_attributes_changed?.should be_true
    end

    it "is false when #event_attributes_changed is empty" do
      abstract_event.stub(:event_attributes_changed => [])
      abstract_event.event_attributes_changed?.should be_false
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

        it "populates and saves the event" do
          expect {
            abstract_event.should_receive(:populate_event).and_call_original
            abstract_event.import!
          }.to change { existing.event.reload.description }

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
          event.changed?.should be_false
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
        abstract_event.event_attributes_changed?.should be_false
      end
    end

    context "when non-event fields have changed" do
      before(:each) { abstract_event.raw_event = 'xyz12493875' }

      it "should not have any event field changes" do
        abstract_event.rebase_changed_attributes!(existing)
        abstract_event.event_attributes_changed?.should be_false
      end
    end

    context "when event fields have changed" do
      before(:each) { abstract_event.title = 'Sandwich Making Contest' }

      it "should report having event field changes" do
        abstract_event.rebase_changed_attributes!(existing)
        abstract_event.event_attributes_changed?.should be_true
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
