class CreateStateCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :state_courses do |t|
      t.references :state, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
