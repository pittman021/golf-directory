class AddDetailsJsonToLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :locations, :details_json, :jsonb
  end
end
