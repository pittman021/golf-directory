class RenameLayoutTagsToCourseTagsInCourses < ActiveRecord::Migration[7.2]
  def change
    rename_column :courses, :layout_tags, :course_tags
  end
end
