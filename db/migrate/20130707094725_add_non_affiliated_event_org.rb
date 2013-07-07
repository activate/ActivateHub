class AddNonAffiliatedEventOrg < ActiveRecord::Migration
  class Organization < ActiveRecord::Base
    self.table_name = 'organizations'
  end

  class Site < ActiveRecord::Base
    self.table_name = 'sites'
  end

  def up
    Site.pluck(:id).each do |site_id|
      Organization.create!(:name => 'A Non-Affiliated Event', :site_id => site_id)
    end
  end

  def down
    Site.pluck(:id).each do |site_id|
      Organization.where(:name => 'A Non-Affiliated Event').each(&:destroy)
    end
  end
end
