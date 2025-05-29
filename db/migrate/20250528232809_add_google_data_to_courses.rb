class AddGoogleDataToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :google_rating, :decimal
    add_column :courses, :google_reviews_count, :integer
    add_column :courses, :formatted_address, :string
    add_column :courses, :opening_hours_text, :text
  end
end
