class Version < ApplicationRecord
  include PaperTrail::VersionConcern

  default_scope -> { current_site ? where(:site_id => current_site.id) : all }

end
