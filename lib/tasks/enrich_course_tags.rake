namespace :courses do
  desc "Enrich course tags based on existing course data"
  task enrich_tags: :environment do
    puts "🏷️ Starting course tag enrichment based on existing data..."
    puts "This will analyze course names, descriptions, amenities, pricing, and location"
    puts "to automatically suggest and apply appropriate tags."
    puts "=" * 70
    
    # Find courses that could benefit from tag enrichment
    courses_to_enrich = Course.where(
      "(course_tags IS NULL OR ARRAY_LENGTH(course_tags, 1) < 3) AND " \
      "(description IS NOT NULL OR amenities IS NOT NULL OR green_fee IS NOT NULL)"
    ).limit(1000) # Process in batches
    
    total_eligible = Course.where(
      "(course_tags IS NULL OR ARRAY_LENGTH(course_tags, 1) < 3) AND " \
      "(description IS NOT NULL OR amenities IS NOT NULL OR green_fee IS NOT NULL)"
    ).count
    
    puts "Found #{courses_to_enrich.count} courses to enrich in this batch"
    puts "Total eligible courses: #{total_eligible}"
    puts ""
    
    enriched_count = 0
    failed_count = 0
    total_tags_added = 0
    tag_statistics = Hash.new(0)
    
    courses_to_enrich.find_each.with_index do |course, index|
      puts "\n#{index + 1}/#{courses_to_enrich.count}: Enriching #{course.name}..."
      puts "  State: #{course.state&.name || 'Unknown'}"
      puts "  Current tags: #{course.course_tags&.any? ? course.course_tags.join(', ') : 'NONE'}"
      puts "  Green fee: $#{course.green_fee || 'Unknown'}"
      puts "  Amenities: #{course.amenities&.count || 0} listed"
      puts "  Description: #{course.description ? "#{course.description.length} chars" : 'None'}"
      
      begin
        original_tags = course.course_tags || []
        
        enrichment_service = CourseTagEnrichmentService.new(course)
        suggested_tags = enrichment_service.enrich_tags
        
        # Reload to get updated tags
        course.reload
        new_tags = course.course_tags || []
        added_tags = new_tags - original_tags
        
        if added_tags.any?
          enriched_count += 1
          total_tags_added += added_tags.count
          
          puts "  ✅ Added #{added_tags.count} tags: #{added_tags.join(', ')}"
          puts "  📊 Final tags: #{new_tags.join(', ')}"
          
          # Track tag statistics
          added_tags.each { |tag| tag_statistics[tag] += 1 }
        else
          puts "  ℹ️ No new tags suggested (course may already be well-tagged)"
        end
        
      rescue => e
        failed_count += 1
        puts "  ❌ Error enriching #{course.name}: #{e.message}"
      end
    end
    
    puts "\n📊 Tag Enrichment Summary:"
    puts "Successfully enriched: #{enriched_count} courses"
    puts "Failed to enrich: #{failed_count} courses"
    puts "Total tags added: #{total_tags_added}"
    puts "Average tags per enriched course: #{enriched_count > 0 ? (total_tags_added.to_f / enriched_count).round(1) : 0}"
    puts "Total processed: #{enriched_count + failed_count} courses"
    puts "Total eligible remaining: #{total_eligible - courses_to_enrich.count} courses"
    
    if tag_statistics.any?
      puts "\n🏷️ Most Added Tags:"
      tag_statistics.sort_by { |tag, count| -count }.first(15).each do |tag, count|
        puts "  #{tag}: #{count} courses"
      end
    end
    
    puts "\n💡 Run again to continue enriching more courses."
    puts "🎯 This enrichment uses existing course data to intelligently suggest tags."
  end
  
  desc "Enrich tags for specific course types or regions"
  task enrich_targeted: :environment do
    puts "🎯 Targeted course tag enrichment"
    puts "Choose a target group for enrichment:"
    puts "1. Top 100 courses"
    puts "2. Resort courses (with lodging amenities)"
    puts "3. High-priced courses ($150+)"
    puts "4. Courses in specific states"
    puts "5. Courses with many amenities but few tags"
    
    print "Enter choice (1-5): "
    choice = STDIN.gets.chomp.to_i
    
    courses_to_enrich = case choice
    when 1
      Course.where("'golf:top100' = ANY(course_tags) OR 'top_100_courses' = ANY(course_tags)")
    when 2
      Course.where("amenities IS NOT NULL AND 'Lodging' = ANY(amenities)")
    when 3
      Course.where("green_fee >= ?", 150)
    when 4
      print "Enter state name: "
      state_name = STDIN.gets.chomp
      Course.joins(:state).where("states.name ILIKE ?", "%#{state_name}%")
    when 5
      Course.where("ARRAY_LENGTH(amenities, 1) >= 5 AND (course_tags IS NULL OR ARRAY_LENGTH(course_tags, 1) <= 2)")
    else
      puts "Invalid choice"
      exit
    end
    
    puts "\nFound #{courses_to_enrich.count} courses matching criteria"
    
    enriched_count = 0
    courses_to_enrich.find_each.with_index do |course, index|
      puts "\n#{index + 1}/#{courses_to_enrich.count}: #{course.name}"
      
      original_tags = course.course_tags || []
      enrichment_service = CourseTagEnrichmentService.new(course)
      enrichment_service.enrich_tags
      
      course.reload
      new_tags = course.course_tags || []
      added_tags = new_tags - original_tags
      
      if added_tags.any?
        enriched_count += 1
        puts "  ✅ Added: #{added_tags.join(', ')}"
      else
        puts "  ℹ️ No new tags"
      end
    end
    
    puts "\n✅ Enriched #{enriched_count} out of #{courses_to_enrich.count} courses"
  end
  
  desc "Show tag enrichment statistics and recommendations"
  task tag_stats: :environment do
    puts "📈 Course Tag Enrichment Statistics"
    puts "=" * 60
    
    total_courses = Course.count
    courses_with_tags = Course.where.not("course_tags IS NULL OR ARRAY_LENGTH(course_tags, 1) IS NULL").count
    courses_with_few_tags = Course.where("ARRAY_LENGTH(course_tags, 1) <= 2").count
    courses_with_no_tags = Course.where("course_tags IS NULL OR ARRAY_LENGTH(course_tags, 1) IS NULL").count
    
    puts "\n🏷️ Tag Coverage:"
    puts "Total courses: #{total_courses}"
    puts "Courses with tags: #{courses_with_tags} (#{(courses_with_tags.to_f / total_courses * 100).round(1)}%)"
    puts "Courses with few tags (≤2): #{courses_with_few_tags} (#{(courses_with_few_tags.to_f / total_courses * 100).round(1)}%)"
    puts "Courses with no tags: #{courses_with_no_tags} (#{(courses_with_no_tags.to_f / total_courses * 100).round(1)}%)"
    
    # Tag distribution
    puts "\n📊 Current Tag Distribution:"
    tag_counts = Hash.new(0)
    Course.pluck(:course_tags).each do |tags|
      next if tags.nil?
      tags.each { |tag| tag_counts[tag] += 1 }
    end
    
    tag_counts.sort_by { |tag, count| -count }.first(20).each do |tag, count|
      puts "  #{tag}: #{count} courses"
    end
    
    # Enrichment opportunities
    puts "\n🎯 Enrichment Opportunities:"
    
    # Courses with rich data but few tags
    rich_data_few_tags = Course.where(
      "ARRAY_LENGTH(course_tags, 1) <= 2 AND " \
      "description IS NOT NULL AND " \
      "amenities IS NOT NULL AND " \
      "green_fee IS NOT NULL"
    ).count
    
    puts "Courses with rich data but few tags: #{rich_data_few_tags}"
    
    # High-value courses without luxury tags
    expensive_no_luxury = Course.where("green_fee >= 200")
                               .where.not("'trip:luxury' = ANY(course_tags)")
                               .count
    puts "Expensive courses ($200+) without luxury tag: #{expensive_no_luxury}"
    
    # Resort amenities without resort tags
    lodging_no_resort = Course.where("amenities IS NOT NULL AND 'Lodging' = ANY(amenities)")
                             .where.not("'golf:resort' = ANY(course_tags)")
                             .count
    puts "Courses with lodging but no resort tag: #{lodging_no_resort}"
    
    puts "\n💡 Recommendations:"
    puts "1. Run 'rails courses:enrich_tags' to auto-tag courses with rich data"
    puts "2. Run 'rails courses:enrich_targeted' for specific course groups"
    puts "3. Focus on courses with descriptions and amenities but few tags"
  end
end 