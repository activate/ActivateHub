class Topic < ActiveRecord::Base
  has_and_belongs_to_many :events
  has_and_belongs_to_many :organizations
  has_and_belongs_to_many :sources

  belongs_to :site
  scope_to_current_site

  attr_protected nil # FIXME: Use strong_params

  # Validations
  validates :name, :presence => true
  validates :name, :uniqueness => { :scope => :site_id, :case_sensitive => false }

  default_scope -> { order('LOWER(topics.name) ASC') }


  def any_items?
    events.any? || organizations.any? || sources.any?
  end

end
