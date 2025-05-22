namespace :seed do
    desc "Enrich stale courses using ChatGPT"
    task enrich_stale_courses: :environment do

    limit = ENV["LIMIT"]&.to_i
    limit = nil if limit == 0
    
      puts "\n=== Enriching Stale Courses ==="
  
      # Courses with empty description
      minimal_courses = Course.where("description IS NULL OR description = ''")
  
      # Courses with the default Google note
      google_imported = Course.where("notes LIKE ?", "%Automatically imported from Google Places API%")
      # Courses with default filler values
  
      # Courses with very few tags
      minimal_tags = Course.where("array_length(course_tags, 1) <= 2")
  
      # Combine all into one unique list
      course_ids = (minimal_courses.pluck(:id) +
                    google_imported.pluck(:id) +
                    default_values.pluck(:id) +
                    minimal_tags.pluck(:id)).uniq
  
      puts "\nTotal courses flagged for enrichment: #{course_ids.size}"
  
      enriched = 0
      failed = 0
  
      Course.where(id: course_ids).find_each.with_index(1) do |course, i|
        puts "\n[#{i}/#{course_ids.size}] Enriching: #{course.name} (#{course.locations.first&.name})"
  
        begin
          service = GetCourseInfoService.new(course)
          result = service.gather_info
          if result
            puts "✅ Enrichment successful"
            enriched += 1
          else
            puts "⚠️ Skipped or no update"
          end
        rescue => e
          puts "❌ Error enriching #{course.name}: #{e.message}"
          failed += 1
        end
  
        sleep 1.5 # avoid hammering GPT-4 API
      end
  
      puts "\n=== Summary ==="
      puts "Courses enriched: #{enriched}"
      puts "Courses failed: #{failed}"
      puts "Skipped (no update): #{course_ids.size - enriched - failed}"
    end
  end
  