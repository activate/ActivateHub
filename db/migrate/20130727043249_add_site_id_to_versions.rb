class AddSiteIdToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :site_id, :integer

    # associates version objects with site for items not yet deleted
    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE versions v SET site_id = (
        SELECT i.site_id FROM events i WHERE i.id = v.item_id
      ) WHERE v.item_type = 'Event';

      UPDATE versions v SET site_id = (
        SELECT i.site_id FROM venues i WHERE i.id = v.item_id
      ) WHERE v.item_type = 'Venue';

      UPDATE versions v SET site_id = (
        SELECT i.site_id FROM sources i WHERE i.id = v.item_id
      ) WHERE v.item_type = 'Source';
    SQL

    # pull site_id from unmarshalled versioned items
    Version.record_timestamps = false
    Version.where(:site_id => nil).each do |version|
      begin
        item = version.reify or next
        version.site_id = item.site_id
        version.save!
      rescue
        # object no longer demarshalls properly, bummer, oh well...
      end
    end

    # go over everything again, might now be a related version w/ site_id
    Version.where(:site_id => nil).each do |version|
      if site_id = version.sibling_versions.map(&:site_id).detect(&:presence)
        # another version for same model item has site_id, use that
        version.site_id = site_id
        version.save!
      end
    end

  end
end
