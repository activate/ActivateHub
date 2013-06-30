class Organization < ActiveRecord::Base
  scope_to_current_site
  belongs_to :site
  has_many :events # we might want :dependent => :destroy later
  has_many :sources, :dependent => :destroy
  has_and_belongs_to_many :topics

  # Validations
  validates :name, presence: true
  validates :contact_name, presence: true
  validates :email, presence: true

  include ValidatesBlacklistOnMixin
  validates_blacklist_on :name, :url

  validates_format_of :url,
    :with => /(http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/,
    :allow_blank => true,
    :allow_nil => true,
    :message => "is invalid (did you include the http:// part?)"

  validates_format_of :email,
    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/,
    :allow_blank => true,
    :allow_nil => true,
    :message => "is invalid (did you include the @ part?)"

  default_scope :order => 'LOWER(name) ASC'

  def title
    @name
  end

end
