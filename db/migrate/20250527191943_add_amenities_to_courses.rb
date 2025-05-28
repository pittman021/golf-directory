class AddAmenitiesToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :amenities, :string, array: true, default: []
    add_index :courses, :amenities, using: :gin
  end
end
