class AddReviewsCountToLocations < ActiveRecord::Migration[7.2]
  def up
    add_column :locations, :reviews_count, :integer, default: 0, null: false

    # Update existing records
    Location.find_each do |location|
      review_count = Review.joins(course: :location_courses)
                         .where(location_courses: { location_id: location.id })
                         .count
      location.update_column(:reviews_count, review_count)
    end
  end

  def down
    remove_column :locations, :reviews_count
  end
end