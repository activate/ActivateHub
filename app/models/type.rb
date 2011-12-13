class Type < ActiveRecord::Base
  has_and_belongs_to_many :events
  has_and_belongs_to_many :sources

  # Validations
  validates_presence_of :name

end
