class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.current_site
    Thread.current[:current_site]
  end

  def self.current_site=(site)
    Thread.current[:current_site] = site
  end

  def self.scope_to_current_site
    default_scope -> { current_site ? where(:site_id => current_site.id) : all }
  end
end
