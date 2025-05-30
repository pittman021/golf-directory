class AddImageUrlToLodgings < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:lodgings, :image_url)
      add_column :lodgings, :image_url, :string
    end
    
    if column_exists?(:lodgings, :photo_reference)
      remove_column :lodgings, :photo_reference, :string
    end
  end
end 