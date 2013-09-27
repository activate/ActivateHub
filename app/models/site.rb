class Site < ActiveRecord::Base
  validates_presence_of :name, :domain

  def venues_google_map_options
    {
      :center => [ map_latitude, map_longitude ],
      :zoom => map_zoom,
    }
  end
end
