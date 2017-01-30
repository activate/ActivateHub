class DowncaseSiteDomains < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      UPDATE sites SET domain = lower(domain);
      UPDATE site_domains SET domain = lower(domain);
    SQL
  end

  def down
    # Nothing to do
  end

end
