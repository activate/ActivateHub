class Topic < ActiveRecord::Base
  has_and_belongs_to_many :events
  has_and_belongs_to_many :organizations
  has_and_belongs_to_many :sources

  belongs_to :site
  scope_to_current_site

  # Validations
  validates_presence_of :name

  default_scope :order => 'LOWER(topics.name) ASC'
end
