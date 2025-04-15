namespace :tags do
  desc "Convert layout_tags to course_tags and update location tags"
  task migrate: :environment do
    puts "Starting tag migration..."
    
    # Step 1: Update all courses with layout_tags -> course_tags
    count = 0
    Course.all.each do |course|
      # If course_tags is already set, skip
      next if course.course_tags.present?
      
      # Map existing layout_tags if available (in this case, the column was renamed)
      if course.respond_to?(:layout_tags) && course.layout_tags.present?
        course.course_tags = course.layout_tags
        count += 1 if course.save
      end
    end
    puts "Updated #{count} courses with course_tags"
    
    # Step 2: Update all locations with derived tags
    count = 0
    Location.all.each do |location|
      begin
        # Add the 'multiple_courses' tag if applicable
        location.update_tags_from_courses!
        count += 1
      rescue => e
        puts "Error updating location #{location.id}: #{e.message}"
      end
    end
    puts "Updated #{count} locations with derived tags"
    
    puts "Tag migration complete!"
  end
end 