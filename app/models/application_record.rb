class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  cattr_accessor :current_site

  def self.scope_to_current_site
    default_scope -> { current_site ? where(:site_id => current_site.id) : all }
  end
end
