class AbstractEvent < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :event
  belongs_to :abstract_location

  EVENT_ATTRIBUTES = [ # attributes that get copied over to events if changed
    :url, :title, :start_time, :end_time, :description, :tags,
  ]

  validates :site_id, :presence => true
  validates :source_id, :presence => true
  validates :title, :presence => true
  validates :start_time, :presence => true
  validates :end_time, :presence => true

  serialize :tags, Array

  scope :invalid, where(:result => 'invalid')


  def abstract_location=(abstract_location)
    self.venue_title = abstract_location.try(:title)
    super
  end

  def event_attributes_changed
    EVENT_ATTRIBUTES.select {|a| changed_attributes.key?(a.to_s) }
  end

  def event_attributes_changed?
    event_attributes_changed.any?
  end

  def find_existing
    # limit search to same source, not trying to de-dupe events, just trying
    # to be smart about looking for shifting abstract events in same source
    abstract_events = self.class.where(:source_id => source.id)

    existing_matchers = [
      { :external_id => external_id },
      { :start_time => start_time, :title => title },
      { :start_time => start_time, :venue_title => venue_title },
    ]

    # all matcher conditions must have a value for matcher to be valid
    existing_matchers.reject! {|m| m.any? {|k,v| v.blank? } }

    existing_matchers.inject(nil) do |existing,matcher_conditions|
      existing ||= abstract_events.where(matcher_conditions).order(:id).last
    end
  end

  def rebase(abstract_event)
    orig_attributes = attributes

    # resets this object's attributes to be identical to abstract_event
    self.attributes = abstract_event.attributes
    changed_attributes.clear

    # apply our original attributes on top, allowing us to identify changes
    self.attributes = orig_attributes

    self
  end

  def save_invalid!
    self.result = 'invalid'
    save!(:validate => false)
  end

end
