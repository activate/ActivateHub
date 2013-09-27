class RemovePathPrefixFromSites < ActiveRecord::Migration
  class Site < ActiveRecord::Base
    self.table_name = 'sites'
  end

  def up
    # this doesn't allow sub-calendars to still work, it's just so we can
    # identify the calendars later to change their domains to something else,
    # and also so they don't conflict with the primary calendar associated
    # with the domain

    sites = Site.where("path_prefix IS NOT NULL AND path_prefix != ''")
    sites.each do |site|
      site.domain += "/#{site.path_prefix}"
      site.save!
    end

    remove_column :sites, :path_prefix
  end

  def down
    add_column :sites, :path_prefix, :string

    Site.where("domain LIKE %/%").each do |site|
      domain, path_prefix = site.domain.partition('/')[0,2]

      site.domain = domain
      site.path_prefix = path_prefix
      site.save!
    end
  end

end
