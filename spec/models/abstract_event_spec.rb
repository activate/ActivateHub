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
      let(:existing) do
        abstract_event.dup # make attributes identical by default
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
