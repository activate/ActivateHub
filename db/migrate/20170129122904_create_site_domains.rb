class CreateSiteDomains < ActiveRecord::Migration[5.0]
  def up
    create_table :site_domains do |t|
      t.references :site, foreign_key: true, null: false
      t.string :domain, null: false
      t.boolean :redirect, null: false, default: true

      t.timestamps null: false
    end

    execute <<-SQL
      INSERT INTO site_domains
        (site_id, domain, redirect, created_at, updated_at)
        SELECT id, domain, false, NOW(), NOW() FROM sites;
    SQL

    add_index :site_domains, :domain, unique: true
  end

  def down
    drop_table :site_domains
  end

end
