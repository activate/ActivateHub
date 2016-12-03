class Type < ApplicationRecord
  has_and_belongs_to_many :events
  has_and_belongs_to_many :sources
  belongs_to :site
  scope_to_current_site

  # Validations
  validates :name, :presence => true
  validates :name, :uniqueness => { :scope => :site_id, :case_sensitive => false }

  default_scope -> { order('LOWER(types.name) ASC') }


  def any_items?
    events.any? || sources.any?
  end

end
