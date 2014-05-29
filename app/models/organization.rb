class Organization < ActiveRecord::Base
  scope_to_current_site
  belongs_to :site
  has_many :events
  has_many :sources
  has_and_belongs_to_many :topics
  belongs_to :default_venue, class_name: "Venue",
                            foreign_key: "default_venue_id"
  # Validations
  validates :name, presence: true

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

  before_save :check_touch_events
  after_save :touch_events

  default_scope :order => 'LOWER(organizations.name) ASC'

  def title
    @name
  end


  private

  def check_touch_events
    @touch_events = name_changed?
    true
  end

  def touch_events
    return unless @touch_events
    events.update_all(:updated_at => Time.zone.now)
    sources.update_all(:updated_at => Time.zone.now)
  end

end
