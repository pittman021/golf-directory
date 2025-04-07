class CreateLocationCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :location_courses do |t|
      t.references :location, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
