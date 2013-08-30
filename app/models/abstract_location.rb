class AbstractLocation < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :venue
  has_many :abstract_events

  VENUE_ATTRIBUTES = [ # attributes that get copied over to venues if changed
    :url, :title, :description, :address, :street_address, :locality, :region,
    :postal_code, :country, :latitude, :longitude, :email, :telephone, :tags,
  ]

  validates :site_id, :presence => true
  validates :source_id, :presence => true
  validates :title, :presence => true

  serialize :tags, Array

  scope :invalid, where(:result => 'invalid')


  def rebase(abstract_location)
    orig_attributes = attributes

    # resets this object's attributes to be identical to abstract_location
    self.attributes = abstract_location.attributes
    changed_attributes.clear

    # apply our original attributes on top, allowing us to identify changes
    self.attributes = orig_attributes

    self
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
