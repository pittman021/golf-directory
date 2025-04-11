class UpdateLocationPriceFields < ActiveRecord::Migration[7.1]
  def change
    # Remove old average cost field
    remove_column :locations, :avg_lodging_cost_per_night, :integer
    
    # Add all price-related fields
    add_column :locations, :lodging_price_min, :integer
    add_column :locations, :lodging_price_max, :integer
    add_column :locations, :lodging_price_currency, :string, default: 'USD'
    add_column :locations, :lodging_price_source, :string
    add_column :locations, :lodging_price_notes, :text
    add_column :locations, :lodging_price_last_updated, :datetime
  end
end 