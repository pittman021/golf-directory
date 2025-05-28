class AddPhoneToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :phone, :string
  end
end
