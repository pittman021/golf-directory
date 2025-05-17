class AddStateIdToCourses < ActiveRecord::Migration[7.2]
  def change
    add_reference :courses, :state, null: false, foreign_key: true
  end
end
