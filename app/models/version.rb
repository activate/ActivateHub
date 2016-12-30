# TODO: Make it so paper trail manager can customize the model to use

class Version < ApplicationRecord
  include PaperTrail::VersionConcern

  cattr_accessor :current_site

  def self.scope_to_current_site
    default_scope -> { current_site ? where(:site_id => current_site.id) : all }
  end

  scope_to_current_site

end
