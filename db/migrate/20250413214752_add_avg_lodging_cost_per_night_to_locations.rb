class AddAvgLodgingCostPerNightToLocations < ActiveRecord::Migration[7.2]
  def change
    unless column_exists?(:locations, :avg_lodging_cost_per_night)
      add_column :locations, :avg_lodging_cost_per_night, :integer
    end
  end
end
