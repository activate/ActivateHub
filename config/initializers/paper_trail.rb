class Version < ActiveRecord::Base
  PaperTrailManager.whodunnit_class = User
  PaperTrailManager.whodunnit_name_method = :email

  attr_accessible :site_id
  scope_to_current_site
end
