class Version < ActiveRecord::Base
  attr_accessible :site_id
  scope_to_current_site
end
