class AddGeoPrecisionTooVenues < ActiveRecord::Migration[5.0]
  def change
    add_column :venues, :geo_precision, :text
  end
end
