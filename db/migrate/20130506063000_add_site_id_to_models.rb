class AddSiteIdToModels < ActiveRecord::Migration
  def self.tables
    [:events, :organizations, :sources, :topics, :types, :venues]
  end

  def self.up
    default_site = Site.find_or_create_by_id 1
    if !default_site.domain
      default_site.domain = "localhost"
      default_site.name = "localhost"
      default_site.save
    end

    tables.each do |table|
      add_column table, :site_id, :integer

      model = table.to_s.classify.constantize
      model.reset_column_information 

      model.update_all "site_id = 1", "site_id IS NULL"
    end
  end

  def self.down
    tables.each do |table|
      remove_column table, :site_id
    end
  end
end
