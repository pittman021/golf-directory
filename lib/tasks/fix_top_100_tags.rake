namespace :courses do
  desc "Fix inconsistent top 100 course tagging by standardizing on top_100_courses tag"
  task fix_top_100_tags: :environment do
    puts "🔧 Starting to fix top 100 course tagging inconsistencies..."
    
    # Get current state
    courses_with_top_100 = Course.where("'top_100' = ANY(course_tags)")
    courses_with_top_100_courses = Course.where("'top_100_courses' = ANY(course_tags)")
    courses_with_both = Course.where("'top_100' = ANY(course_tags) AND 'top_100_courses' = ANY(course_tags)")
    
    puts "\n📊 Current State:"
    puts "Courses with 'top_100' tag: #{courses_with_top_100.count}"
    puts "Courses with 'top_100_courses' tag: #{courses_with_top_100_courses.count}"
    puts "Courses with both tags: #{courses_with_both.count}"
    
    # Find courses that have top_100 but not top_100_courses
    courses_to_update = Course.where("'top_100' = ANY(course_tags) AND NOT ('top_100_courses' = ANY(course_tags))")
    
    puts "\n🔄 Courses that need 'top_100_courses' tag added: #{courses_to_update.count}"
    
    updated_count = 0
    failed_updates = []
    
    courses_to_update.find_each do |course|
      begin
        # Add top_100_courses tag
        course.course_tags ||= []
        course.course_tags << "top_100_courses"
        
        if course.save
          updated_count += 1
          puts "✅ Added 'top_100_courses' tag to: #{course.name}"
        else
          failed_updates << { course: course, errors: course.errors.full_messages }
          puts "❌ Failed to update #{course.name}: #{course.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        failed_updates << { course: course, errors: [e.message] }
        puts "❌ Error updating #{course.name}: #{e.message}"
      end
    end
    
    puts "\n📊 Update Results:"
    puts "Successfully updated: #{updated_count}"
    puts "Failed updates: #{failed_updates.count}"
    
    if failed_updates.any?
      puts "\n❌ Failed Updates:"
      failed_updates.each do |failure|
        puts "- #{failure[:course].name}: #{failure[:errors].join(', ')}"
      end
    end
    
    # Now remove old top_100 tags
    puts "\n🧹 Removing old 'top_100' tags..."
    
    courses_with_old_tag = Course.where("'top_100' = ANY(course_tags)")
    removed_count = 0
    
    courses_with_old_tag.find_each do |course|
      begin
        # Remove top_100 tag
        course.course_tags = course.course_tags.reject { |tag| tag == "top_100" }
        
        if course.save
          removed_count += 1
          puts "🗑️ Removed 'top_100' tag from: #{course.name}"
        else
          puts "❌ Failed to remove tag from #{course.name}: #{course.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        puts "❌ Error removing tag from #{course.name}: #{e.message}"
      end
    end
    
    puts "\n📊 Cleanup Results:"
    puts "Old tags removed: #{removed_count}"
    
    # Final verification
    puts "\n🔍 Final Verification:"
    final_top_100 = Course.where("'top_100' = ANY(course_tags)").count
    final_top_100_courses = Course.where("'top_100_courses' = ANY(course_tags)").count
    
    puts "Courses with 'top_100' tag: #{final_top_100}"
    puts "Courses with 'top_100_courses' tag: #{final_top_100_courses}"
    
    puts "\n✅ Top 100 course tagging fix completed!"
    puts "The top 100 courses page should now show all #{final_top_100_courses} courses."
  end
end 