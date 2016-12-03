class AbstractLocation < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :venue
  has_many :abstract_events

  include Rebaseable

  scope_to_current_site

  VENUE_ATTRIBUTES = [ # attributes that get copied over to venues if changed
    :url, :title, :description, :address, :street_address, :locality, :region,
    :postal_code, :country, :latitude, :longitude, :email, :telephone,
    # :tags, # FIXME: is :tags_list in Venue (:changed doesn't match up in populate_venue)
  ]

  validates :site_id, :presence => true
  validates :source_id, :presence => true
  validates :title, :presence => true

  serialize :tags, Array

  scope :invalid, -> { where(:result => 'invalid') }


  def find_existing
    # limit search to same source, not trying to de-dupe venues, just trying
    # to be smart about looking for shifting abstract locations in same source
    abstract_locations = self.class.where(:source_id => source.id)

    matchers = [
      # note: lat+long not exact enough, can have mult. venues within a building
      { :external_id => external_id },
      { :title => title },
    ]

    # all matcher conditions must have a value for matcher to be valid
    matchers.reject! {|m| m.any? {|k,v| v.blank? } }

    # address can be matched as long as it has street-level info
    if street_address.present?
      matchers << {
        :address        => address,
        :street_address => street_address,
        :locality       => locality,
        :region         => region,
        :postal_code    => postal_code,
      }
    end

    existing = matchers.find do |matcher_conditions|
      if matched = abstract_locations.where(matcher_conditions).order(:id).last
        if venue_id = matched.venue_id
          # matcher value might've changed, can now tie to venue and find latest
          # can get a better match; the matcher might've found an older copy
          matched = abstract_locations.where(:venue_id => venue_id).order(:id).last
        else
          # probably was invalid and never created a venue, use original match
        end

        break matched
      end
    end

    existing
  end

  def import!
    # layer our changes on top of an existing location if one found
    if existing = find_existing
      rebase_changed_attributes!(existing)
    end

    if venue_attributes_changed?
      self.result = (existing ? 'updated' : 'created')
      populate_venue
      venue.save! if venue
      save!
    else
      self.id = existing.id
      self.result = 'unchanged'
    end

    result
  end

  def populate_venue
    if self.venue
      # make sure we're making changes to progenitor, not slave/dupe venue
      self.venue = venue.progenitor
    elsif self.venue_id
      # had a venue, but was explicitly removed; nothing to do
      return
    else
      # new venue
      self.venue = Venue.new(:source_id => source_id)
    end

    venue_attributes_changed.each do |name|
      if venue[name] == send("#{name}_was")
        # venue value unchanged from value set in last abstract location, safe
        venue.send("#{name}=", send(name))
      else
        # venue value has been updated outside of abstract locations; we don't
        # know if it's safe to update this value anymore, ignore the change
      end
    end

    venue
  end

  def save_invalid!
    self.result = 'invalid'
    save!(:validate => false)
  end

  def venue_attributes_changed
    VENUE_ATTRIBUTES.select {|a| changed_attributes.key?(a.to_s) }
  end

  def venue_attributes_changed?
    venue_attributes_changed.any?
  end

end
