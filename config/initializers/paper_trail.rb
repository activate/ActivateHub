PaperTrailManager.whodunnit_class = User
PaperTrailManager.whodunnit_name_method = :email
PaperTrailManager.allow_index_when do |controller, version|
  controller.current_user and controller.current_user.admin?
end
