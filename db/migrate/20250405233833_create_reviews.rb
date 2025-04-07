class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :rating
      t.date :played_on
      t.string :course_condition
      t.text :comment

      t.timestamps
    end
  end
end
