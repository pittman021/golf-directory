class AddImageUrlToLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :locations, :image_url, :string
  end
end
