PaperTrailManager.version_model = '::Version'

PaperTrailManager.whodunnit_class = User
PaperTrailManager.whodunnit_name_method = :email
PaperTrailManager.user_path_method = nil # Suppress link to user profile page

PaperTrailManager.allow_index_when do |controller, version|
  controller.current_user and controller.current_user.admin?
end

PaperTrail.config.track_associations = false
