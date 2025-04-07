class CreateCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :courses do |t|
      t.string :name
      t.text :description
      t.decimal :latitude
      t.decimal :longitude
      t.integer :course_type
      t.string :green_fee_range
      t.integer :number_of_holes
      t.integer :par
      t.integer :yardage
      t.string :website_url

      t.timestamps
    end
  end
end
