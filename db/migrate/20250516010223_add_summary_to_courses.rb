class AddSummaryToCourses < ActiveRecord::Migration[7.2]
  def change
    add_column :courses, :summary, :json
  end
end
