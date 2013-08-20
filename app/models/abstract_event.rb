class AbstractEvent < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :event
  belongs_to :abstract_location

  validates :site_id, :presence => true
  validates :source_id, :presence => true

  serialize :tags, Array


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

end
