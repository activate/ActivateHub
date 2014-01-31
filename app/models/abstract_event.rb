class AbstractEvent < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :event
  belongs_to :abstract_location

  include DirtyAttrAccessor
  include Rebaseable

  scope_to_current_site

  after_find :populate_venue_id

  dirty_attr_accessor :venue_id

  EVENT_ATTRIBUTES = [ # attributes that get copied over to events if changed
    :url, :title, :end_time, :start_time, :description, :venue_id
    #:tags, # FIXME: is :tags_list in Event (:changed doesn't match up in populate_event)
  ]

  validates :site_id, :presence => true
  validates :source_id, :presence => true
  validates :title, :presence => true
  validates :start_time, :presence => true
  validates :end_time, :presence => true

  serialize :tags, Array

  scope :invalid, where(:result => 'invalid')


  def abstract_location=(abstract_location)
    # keep a copy of venue title so we don't have to hit database for
    # abstract locations when detecting if event exists in :find_existing
    self.venue_title = abstract_location.try(:title)
    self.venue_id = abstract_location.try(:venue_id)

    super
  end

  def attributes
    super.merge!('venue_id' => venue_id)
  end

  def event_attributes_changed
    # ensures venue_id is current as dirty attrs uses cached value
    self.venue_id = abstract_location.try(:venue_id)

    EVENT_ATTRIBUTES.select {|a| changed_attributes.key?(a.to_s) }
  end

  def event_attributes_changed?
    event_attributes_changed.any?
  end

  def find_existing
    # limit search to same source, not trying to de-dupe events, just trying
    # to be smart about looking for shifting abstract events in same source
    abstract_events = self.class.where(:source_id => source.id)

    matchers = [
      { :external_id => external_id },
      { :start_time => start_time, :title => title },
      { :start_time => start_time, :venue_title => venue_title },
    ]

    # all matcher conditions must have a value for matcher to be valid
    matchers.reject! {|m| m.any? {|k,v| v.blank? } }

    existing = matchers.find do |matcher_conditions|
      if matched = abstract_events.where(matcher_conditions).order(:id).last
        if event_id = matched.event_id
          # matcher value might've changed, can now tie to event and find latest
          matched = abstract_events.where(:event_id => event_id).order(:id).last
        else
          # probably was invalid and never created an event, use original match
        end

        break matched
      end
    end

    existing
  end

  def import!
    # layer our changes on top of an existing event if one found
    if existing = find_existing
      rebase_changed_attributes!(existing)
    end

    # import the venue if it hasn't been done already
    if abstract_location && !abstract_location.result?
      begin
        abstract_location.import!
      rescue ActiveRecord::RecordInvalid => e
        abstract_location.save_invalid!
      end
    end

    if event_attributes_changed?
      self.result = (existing ? 'updated' : 'created')
      populate_event
      event.save!
      save!
    else
      self.id = existing.id
      self.result = 'unchanged'
    end

    result
  end

  def populate_event
    self.event ||= Event.new(:source_id => source_id)

    event_attributes_changed.each do |name|
      if event.send(name) == send("#{name}_was")
        # event value unchanged from value set in last abstract event, safe
        event.send("#{name}=", send(name))
      else
        # event value has been updated outside of abstract events; we don't
        # know if it's safe to update this value anymore, ignore the change
      end
    end

    event
  end

  def save_invalid!
    self.result = 'invalid'
    save!(:validate => false)
  end


  private

  def populate_venue_id
    @venue_id = abstract_location.try(:venue_id)
  end

end
