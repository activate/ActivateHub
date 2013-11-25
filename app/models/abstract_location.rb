class AbstractLocation < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :venue
  has_many :abstract_events

  include Rebaseable

  VENUE_ATTRIBUTES = [ # attributes that get copied over to venues if changed
    :url, :title, :description, :address, :street_address, :locality, :region,
    :postal_code, :country, :latitude, :longitude, :email, :telephone, :tags,
  ]

  validates :site_id, :presence => true
  validates :source_id, :presence => true
  validates :title, :presence => true

  serialize :tags, Array

  scope :invalid, where(:result => 'invalid')


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

    abstract_location = matchers.inject(nil) do |existing,matcher_conditions|
      existing ||= abstract_locations.where(matcher_conditions).order(:id).last
    end

    abstract_location
  end

  def import!
    # layer our changes on top of an existing location if one found
    if existing = find_existing
      rebase_changed_attributes!(existing)
    end

    if venue_attributes_changed?
      self.result = (existing ? 'updated' : 'created')
      save!
    else
      self.result = 'unchanged'
    end

    result
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
