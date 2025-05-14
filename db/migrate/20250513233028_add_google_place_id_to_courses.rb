class AddGooglePlaceIdToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :google_place_id, :string
  end
end
