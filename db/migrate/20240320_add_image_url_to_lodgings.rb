class AddImageUrlToLodgings < ActiveRecord::Migration[7.1]
  def change
    add_column :lodgings, :image_url, :string
    remove_column :lodgings, :photo_reference, :string
  end
end 