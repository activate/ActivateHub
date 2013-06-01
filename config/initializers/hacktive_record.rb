class ActiveRecord::Base
  cattr_accessor :current_site

  def self.scope_to_current_site
    default_scope lambda {
      where(:site_id => current_site.id) unless current_site.nil?
    }
  end
end