class Topic < ActiveRecord::Base
  has_and_belongs_to_many :events
  has_and_belongs_to_many :organizations

  # Validations
  validates_presence_of :name

  default_scope :order => 'name ASC'
end
