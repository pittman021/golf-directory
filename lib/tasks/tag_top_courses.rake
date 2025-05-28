require 'fuzzy_match'

# Only load if the constant isn't already defined
load 'lib/golf_data/top_100_courses.rb' unless defined?(GolfData::TOP_COURSES)

namespace :courses do
  desc "Tag top 100 courses or create them via Google Places if missing"
  task tag_top_100: :environment do
    puts "🔍 Starting to tag top 100 courses..."

    # Initialize tracking arrays
    tagged_courses = []
    not_found_courses = []
    already_tagged_courses = []
    created_courses = []

    # Fetch all courses from database
    puts "Fetching all courses from database..."
    all_courses = Course.all.to_a
    
    GolfData::TOP_COURSES.each do |top_course|
      normalized_name = top_course[:name].strip.downcase.gsub(/\s+/, ' ')
      
      # Try to find an exact match (case insensitive)
      course = all_courses.find do |db_course|
        db_course.name.strip.downcase.gsub(/\s+/, ' ') == normalized_name
      end

      # If no exact match, try fuzzy matching
      unless course
        fuzzy_matcher = FuzzyMatch.new(all_courses, read: :name)
        course = fuzzy_matcher.find(top_course[:name])
        
        # Only accept fuzzy matches with high confidence
        if course
          similarity = course.name.downcase.include?(top_course[:name].downcase.split.first) ||
                      top_course[:name].downcase.include?(course.name.downcase.split.first)
          course = nil unless similarity
        end
      end

      if course
        if course.course_tags&.include?("top_100_courses")
          already_tagged_courses << {
            name: course.name,
            id: course.id,
            original_name: top_course[:name]
          }
        else
          # Initialize course_tags if nil
          course.course_tags ||= []
          course.course_tags << "top_100_courses"
          
          if course.save
            tagged_courses << {
              name: course.name,
              id: course.id,
              original_name: top_course[:name]
            }
          else
            puts "❌ Error saving #{course.name}: #{course.errors.full_messages.join(', ')}"
          end
        end
      else
        # Course not found in database, try to fetch from Google Places API
        puts "\n🔍 Course not found in database: #{top_course[:name]}"
        puts "   Searching Google Places API..."
        
        begin
          # Use FindCoursesByNameService to search for the course
          search_query = "#{top_course[:name]} #{top_course[:state]}"
          service = FindCoursesByNameService.new(search_query)
          found_courses = service.find_and_create
          
          if found_courses.any?
            # Find the best match from the results
            best_match = found_courses.find do |found_course|
              # Check if the found course name is similar to what we're looking for
              found_name = found_course.name.strip.downcase.gsub(/\s+/, ' ')
              target_name = top_course[:name].strip.downcase.gsub(/\s+/, ' ')
              
              # Check for exact match or if one contains the other
              found_name == target_name ||
              found_name.include?(target_name.split.first) ||
              target_name.include?(found_name.split.first)
            end
            
            if best_match
              # Tag the course as top_100
              best_match.course_tags ||= []
              best_match.course_tags << "top_100_courses" unless best_match.course_tags.include?("top_100_courses")
              
              if best_match.save
                created_courses << {
                  name: best_match.name,
                  id: best_match.id,
                  original_name: top_course[:name],
                  state: top_course[:state]
                }
                puts "✅ Created and tagged: #{best_match.name}"
                
                # Add to all_courses array for future fuzzy matching
                all_courses << best_match
              else
                puts "❌ Error saving created course: #{best_match.errors.full_messages.join(', ')}"
                not_found_courses << top_course
              end
            else
              puts "⚠️ Found courses but none matched well enough"
              not_found_courses << top_course
            end
          else
            puts "⚠️ No courses found on Google Places API"
            not_found_courses << top_course
          end
          
          # Add a small delay to respect API rate limits
          sleep(1)
          
        rescue StandardError => e
          puts "❌ Error searching Google Places API: #{e.message}"
          not_found_courses << top_course
        end
      end
    end

    # Print summary
    puts "\n📊 Summary:"
    puts "Total top 100 courses processed: #{GolfData::TOP_COURSES.size}"
    puts "Already tagged: #{already_tagged_courses.size}"
    puts "Newly tagged (existing): #{tagged_courses.size}"
    puts "Created and tagged (new): #{created_courses.size}"
    puts "Not found: #{not_found_courses.size}"

    if tagged_courses.any?
      puts "\n✅ Newly Tagged Existing Courses:"
      tagged_courses.each do |course|
        puts "- #{course[:name]} (ID: #{course[:id]})"
        puts "  Original: #{course[:original_name]}" if course[:name] != course[:original_name]
      end
    end

    if created_courses.any?
      puts "\n🆕 Created and Tagged New Courses:"
      created_courses.each do |course|
        puts "- #{course[:name]} (ID: #{course[:id]})"
        puts "  Original: #{course[:original_name]} (#{course[:state]})"
      end
    end

    if already_tagged_courses.any?
      puts "\nℹ️ Already Tagged Courses:"
      already_tagged_courses.each do |course|
        puts "- #{course[:name]} (ID: #{course[:id]})"
        puts "  Original: #{course[:original_name]}" if course[:name] != course[:original_name]
      end
    end

    if not_found_courses.any?
      puts "\n❌ Courses Still Not Found:"
      not_found_courses.each do |course|
        puts "- #{course[:name]} (#{course[:state]})"
      end

      # Save not found courses to a file
      file_path = Rails.root.join('tmp', 'not_found_top_courses.txt')
      File.open(file_path, 'w') do |file|
        file.puts "Top 100 Courses Not Found in Database or Google Places API (as of #{Time.current.strftime('%Y-%m-%d %H:%M:%S')})"
        file.puts "============================================================================="
        not_found_courses.each do |course|
          file.puts "#{course[:name]} (#{course[:state]})"
        end
      end
      puts "\n📝 List of not found courses saved to: #{file_path}"
    end

    puts "\n🎯 Finished tagging top 100 courses."
    puts "Total courses now tagged as top_100: #{Course.where("'top_100_courses' = ANY(course_tags)").count}"
  end
end
