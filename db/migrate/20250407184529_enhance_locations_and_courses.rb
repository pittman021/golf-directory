class EnhanceLocationsAndCourses < ActiveRecord::Migration[7.2]
  def change
    # Enhance locations table
    change_table :locations do |t|
      t.integer :avg_green_fee
      t.integer :avg_lodging_cost_per_night
      t.integer :estimated_trip_cost
      t.string :tags, array: true, default: []  # For storing vibes like 'coastal', 'mountains', etc.
      t.text :summary  # Plain-language overview of the destination
    end

    # Enhance courses table
    change_table :courses do |t|
      t.string :layout_tags, array: true, default: []  # For storing course features like 'water holes', 'elevation'
      t.string :notes  # Additional context about the course
      t.integer :green_fee  # Individual course green fee
    end

    # Add indexes for performance
    add_index :locations, :tags, using: 'gin'
    add_index :locations, :region
    add_index :locations, :state
    add_index :courses, :layout_tags, using: 'gin'
    add_index :courses, :green_fee
  end

  # Add a rollback in case we need to undo these changes
  def down
    remove_index :locations, :tags
    remove_index :locations, :region
    remove_index :locations, :state
    remove_index :courses, :layout_tags
    remove_index :courses, :green_fee

    remove_column :locations, :avg_green_fee
    remove_column :locations, :avg_lodging_cost_per_night
    remove_column :locations, :estimated_trip_cost
    remove_column :locations, :tags
    remove_column :locations, :summary

    remove_column :courses, :layout_tags
    remove_column :courses, :notes
    remove_column :courses, :green_fee
  end
end
