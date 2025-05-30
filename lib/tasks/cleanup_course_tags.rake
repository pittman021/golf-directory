require_relative '../../config/initializers/standardized_course_tags'

namespace :courses do
  desc "Clean up and standardize course tags"
  task cleanup_tags: :environment do
    puts "🧹 Starting course tag cleanup and standardization..."
    
    total_courses = Course.count
    updated_courses = 0
    courses_with_changes = []
    courses_with_default_tag = 0
    tag_statistics = {
      removed: Hash.new(0),
      mapped: Hash.new(0),
      kept: Hash.new(0)
    }
    
    puts "📊 Total courses to process: #{total_courses}"
    
    Course.find_each.with_index do |course, index|
      # Show progress every 100 courses
      if (index + 1) % 100 == 0
        puts "\n📍 Progress: #{index + 1}/#{total_courses} courses processed"
        puts "   Updated so far: #{updated_courses}"
        puts "   Processing: #{course.name[0..50]}..."
      end
      
      original_tags = course.course_tags || []
      next if original_tags.empty?
      
      cleaned_tags = []
      changes_made = false
      changes_log = []
      
      original_tags.each do |tag|
        if TAGS_TO_REMOVE.include?(tag)
          # Remove completely
          tag_statistics[:removed][tag] += 1
          changes_made = true
          changes_log << "REMOVED: #{tag}"
        elsif TAG_CLEANUP_MAPPING.key?(tag)
          # Map to standardized tag
          mapped_tag = TAG_CLEANUP_MAPPING[tag]
          if mapped_tag.nil?
            # Mapping says to remove this tag
            tag_statistics[:removed][tag] += 1
            changes_made = true
            changes_log << "REMOVED: #{tag} (mapped to nil)"
          else
            cleaned_tags << mapped_tag
            tag_statistics[:mapped]["#{tag} -> #{mapped_tag}"] += 1
            changes_made = true
            changes_log << "MAPPED: #{tag} -> #{mapped_tag}"
          end
        else
          # Keep as-is (might be already standardized)
          cleaned_tags << tag
          tag_statistics[:kept][tag] += 1
          changes_log << "KEPT: #{tag}"
        end
      end
      
      # Remove duplicates and sort
      cleaned_tags = cleaned_tags.uniq.sort
      
      # Allow empty tags for now - no default tag needed
      # if cleaned_tags.empty?
      #   cleaned_tags = ["golf:course"] # Generic golf course tag
      #   courses_with_default_tag += 1
      #   changes_made = true
      # end
      
      if changes_made || cleaned_tags != original_tags
        begin
          course.update!(course_tags: cleaned_tags)
          updated_courses += 1
          
          # Log the changes for this course
          puts "✅ #{course.name} (ID: #{course.id})"
          puts "   Before: [#{original_tags.join(', ')}]"
          puts "   After:  [#{cleaned_tags.join(', ')}]"
          changes_log.each { |change| puts "   #{change}" }
          puts ""
          
          courses_with_changes << {
            id: course.id,
            name: course.name,
            original: original_tags,
            cleaned: cleaned_tags,
            changes: changes_log
          }
        rescue => e
          puts "\n❌ Error updating course #{course.name}: #{e.message}"
        end
      end
    end
    
    puts "\n\n✅ Course tag cleanup completed!"
    puts "=" * 60
    puts "📊 Summary:"
    puts "Total courses processed: #{total_courses}"
    puts "Courses updated: #{updated_courses}"
    puts "Courses unchanged: #{total_courses - updated_courses}"
    puts "Courses given default tag: #{courses_with_default_tag}"
    
    puts "\n🗑️ Tags Removed (#{tag_statistics[:removed].values.sum} total):"
    tag_statistics[:removed].sort_by { |tag, count| -count }.first(20).each do |tag, count|
      puts "  #{tag}: #{count} courses"
    end
    
    puts "\n🔄 Tags Mapped (#{tag_statistics[:mapped].size} mappings):"
    tag_statistics[:mapped].sort_by { |mapping, count| -count }.first(20).each do |mapping, count|
      puts "  #{mapping}: #{count} courses"
    end
    
    puts "\n✅ Tags Kept (top 20):"
    tag_statistics[:kept].sort_by { |tag, count| -count }.first(20).each do |tag, count|
      puts "  #{tag}: #{count} courses"
    end
    
    # Save detailed report
    report_path = Rails.root.join('tmp', 'course_tag_cleanup_report.txt')
    File.open(report_path, 'w') do |file|
      file.puts "Course Tag Cleanup Report - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
      file.puts "=" * 80
      file.puts
      
      file.puts "SUMMARY:"
      file.puts "Total courses processed: #{total_courses}"
      file.puts "Courses updated: #{updated_courses}"
      file.puts "Courses unchanged: #{total_courses - updated_courses}"
      file.puts "Courses given default tag: #{courses_with_default_tag}"
      file.puts
      
      file.puts "TAGS REMOVED:"
      tag_statistics[:removed].sort_by { |tag, count| -count }.each do |tag, count|
        file.puts "  #{tag}: #{count} courses"
      end
      file.puts
      
      file.puts "TAGS MAPPED:"
      tag_statistics[:mapped].sort_by { |mapping, count| -count }.each do |mapping, count|
        file.puts "  #{mapping}: #{count} courses"
      end
      file.puts
      
      file.puts "TAGS KEPT:"
      tag_statistics[:kept].sort_by { |tag, count| -count }.each do |tag, count|
        file.puts "  #{tag}: #{count} courses"
      end
      file.puts
      
      file.puts "SAMPLE COURSE CHANGES:"
      courses_with_changes.first(50).each do |change|
        file.puts "Course: #{change[:name]} (ID: #{change[:id]})"
        file.puts "  Before: #{change[:original].join(', ')}"
        file.puts "  After:  #{change[:cleaned].join(', ')}"
        file.puts
      end
    end
    
    puts "\n📝 Detailed report saved to: #{report_path}"
    
    # Show final tag distribution
    puts "\n🏷️ Final tag distribution:"
    final_tag_counts = Hash.new(0)
    Course.pluck(:course_tags).each do |tags|
      next if tags.nil?
      tags.each { |tag| final_tag_counts[tag] += 1 }
    end
    
    final_tag_counts.sort_by { |tag, count| -count }.first(30).each do |tag, count|
      puts "  #{tag}: #{count}"
    end
    
    puts "\n🎯 Next steps:"
    puts "1. Review the report at #{report_path}"
    puts "2. Update forms and views to use the new tag structure"
    puts "3. Consider adding architect and management_company fields to courses"
    puts "4. Review courses with default 'golf:course' tag and add more specific tags"
  end
  
  desc "Preview tag cleanup without making changes"
  task preview_cleanup: :environment do
    puts "🔍 Previewing course tag cleanup (no changes will be made)..."
    
    tag_analysis = {
      to_remove: Hash.new(0),
      to_map: Hash.new(0),
      to_keep: Hash.new(0),
      would_be_empty: 0
    }
    
    Course.pluck(:course_tags).each do |tags|
      next if tags.nil?
      
      cleaned_tags = []
      
      tags.each do |tag|
        if TAGS_TO_REMOVE.include?(tag)
          tag_analysis[:to_remove][tag] += 1
        elsif TAG_CLEANUP_MAPPING.key?(tag)
          mapped_tag = TAG_CLEANUP_MAPPING[tag]
          if mapped_tag.nil?
            tag_analysis[:to_remove][tag] += 1
          else
            cleaned_tags << mapped_tag
            tag_analysis[:to_map]["#{tag} -> #{mapped_tag}"] += 1
          end
        else
          cleaned_tags << tag
          tag_analysis[:to_keep][tag] += 1
        end
      end
      
      # Check if course would end up empty
      if cleaned_tags.empty?
        tag_analysis[:would_be_empty] += 1
      end
    end
    
    puts "\n📊 Preview Results:"
    puts "=" * 50
    
    puts "\n🗑️ Tags to be REMOVED (#{tag_analysis[:to_remove].values.sum} total occurrences):"
    tag_analysis[:to_remove].sort_by { |tag, count| -count }.each do |tag, count|
      puts "  #{tag}: #{count} courses"
    end
    
    puts "\n🔄 Tags to be MAPPED:"
    tag_analysis[:to_map].sort_by { |mapping, count| -count }.each do |mapping, count|
      puts "  #{mapping}: #{count} courses"
    end
    
    puts "\n✅ Tags to be KEPT:"
    tag_analysis[:to_keep].sort_by { |tag, count| -count }.each do |tag, count|
      puts "  #{tag}: #{count} courses"
    end
    
    puts "\n⚠️ Courses that would end up with no tags: #{tag_analysis[:would_be_empty]}"
    puts "   (These will get a default 'golf:course' tag)"
    
    puts "\n💡 Run 'rails courses:cleanup_tags' to apply these changes"
  end
end 