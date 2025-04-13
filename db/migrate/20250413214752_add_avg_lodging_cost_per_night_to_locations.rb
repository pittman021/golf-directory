class AddAvgLodgingCostPerNightToLocations < ActiveRecord::Migration[7.2]
  def change
    add_column :locations, :avg_lodging_cost_per_night, :integer
  end
end
