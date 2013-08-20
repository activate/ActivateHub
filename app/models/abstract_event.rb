class AbstractEvent < ActiveRecord::Base
  belongs_to :site
  belongs_to :source
  belongs_to :event
  belongs_to :abstract_location

  validates :site_id, :presence => true
  validates :source_id, :presence => true

  serialize :tags, Array

end
