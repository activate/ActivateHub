class AddSiteIdToModels < ActiveRecord::Migration
  def self.tables
    [:events, :organizations, :sources, :topics, :types, :venues]
  end

  def self.up
    tables.each do |table|
      add_column table, :site_id, :integer
    end
  end

  def self.down
    tables.each do |table|
      remove_column table, :site_id
    end
  end
end
