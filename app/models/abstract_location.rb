class AbstractLocation < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :venue
  has_many :abstract_events

  validates :site_id, :presence => true
  validates :source_id, :presence => true

  serialize :tags, Array

end
