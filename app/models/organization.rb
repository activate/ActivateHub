class Organization < ActiveRecord::Base
  has_many :events # we might want :dependent => :destroy later
  has_many :sources, :dependent => :destroy
  has_and_belongs_to_many :topics

  # Validations
  validates_presence_of :name

  include ValidatesBlacklistOnMixin
  validates_blacklist_on :name, :url

  validates_format_of :url,
    :with => /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/,
    :allow_blank => true,
    :allow_nil => true,
    :message => "is invalid (did you include the http:// part?)"

  default_scope :order => 'name ASC'

  def title
    @name
  end

end
