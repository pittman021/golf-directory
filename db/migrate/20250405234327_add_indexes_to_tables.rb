# db/migrate/[TIMESTAMP]_add_indexes_to_tables.rb
class AddIndexesToTables < ActiveRecord::Migration[7.2]
  def change
    add_index :courses, :name
    add_index :courses, :course_type
    add_index :locations, :name
    add_index :locations, [:latitude, :longitude]
    add_index :reviews, [:user_id, :course_id, :played_on], unique: true
  end
end
