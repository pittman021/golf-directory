class AddStateAndCityToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :state, :string
    add_column :courses, :city, :string
  end
end
