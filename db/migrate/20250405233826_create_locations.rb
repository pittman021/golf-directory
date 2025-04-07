class CreateLocations < ActiveRecord::Migration[7.2]
  def change
    create_table :locations do |t|
      t.string :name
      t.text :description
      t.decimal :latitude
      t.decimal :longitude
      t.string :region
      t.string :state
      t.string :country
      t.string :best_months
      t.text :nearest_airports
      t.text :weather_info

      t.timestamps
    end
  end
end
