class Site < ActiveRecord::Base
  validates_presence_of :name, :domain

  # "my.site.tld"               => [_, "my.site.tld", nil]
  # "my.site.tld/"              => [_, "my.site.tld", nil]
  # "my.site.tld/cal2"          => [_, "my.site.tld", "cal2"]
  # "my.site.tld/cal2/whatever" => [_, "my.site.tld", "cal2"]
  SITE_PATH_REGEXP = /\A([^\/]+)(?:\/(.+))?/

  def self.find_by_site_path(site_path) # "#{domain}/#{path_prefix}"
    domain, path_prefix = SITE_PATH_REGEXP.match(site_path).to_a[1..2]
    find_by_domain_and_path_prefix!(domain, path_prefix)
  end

  def site_path
    domain + (path_prefix ? '/' + path_prefix : '')
  end

  def venues_google_map_options
    {
      :center => [ map_latitude, map_longitude ],
      :zoom => map_zoom,
    }
  end
end
