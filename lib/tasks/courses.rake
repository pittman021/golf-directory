namespace :courses do
  desc "Enrich courses for a specific location"
  task :enrich_location, [:location_name] => :environment do |t, args|
    if args[:location_name].blank?
      puts "Please provide a location name. Usage: rails courses:enrich_location[location_name]"
      exit 1
    end

    puts "Starting course enrichment for #{args[:location_name]}..."
    
    # Find the location
    location = Location.find_by(name: args[:location_name])
    if location.nil?
      puts "Error: Location '#{args[:location_name]}' not found"
      exit 1
    end
    
    # Get all courses for the location
    courses = location.courses
    if courses.empty?
      puts "No courses found for #{location.name}"
      exit 1
    end
    
    puts "Found #{courses.count} courses in #{location.name}"
    puts "Processing all courses..."
    
    # Process all courses
    courses.each do |course|
      puts "\nProcessing course: #{course.name}"
      
      begin
        service = GetCourseInfoService.new(course)
        course_info = service.gather_info
        
        if course_info
          puts "Successfully enriched course: #{course.name}"
          puts "Updated fields:"
          puts "- Description: #{course.description&.truncate(50)}"
          puts "- Number of holes: #{course.number_of_holes}"
          puts "- Par: #{course.par}"
          puts "- Yardage: #{course.yardage}"
          puts "- Green fee: $#{course.green_fee}"
          puts "- Course type: #{course.course_type}"
          puts "- Layout tags: #{course.course_tags.join(', ')}"
          
          # Add a small delay to avoid hitting API rate limits
          sleep 2
        else
          puts "Failed to enrich course: #{course.name}"
        end
      rescue => e
        puts "Error processing course #{course.name}: #{e.message}"
        puts e.backtrace.join("\n")
      end
    end
    
    puts "\nCompleted processing all #{courses.count} courses for #{location.name}"
  end

  desc "Enrich all courses for all locations"
  task enrich_all: :environment do
    puts "Starting enrichment for all locations..."
    
    Location.find_each do |location|
      puts "\nProcessing #{location.name}..."
      service = FindCoursesByLocationService.new(location)
      service.find_and_enrich
      
      # Add a small delay to avoid hitting API rate limits
      sleep 2
    end
    
    puts "\nEnrichment process completed!"
  end

  desc "Update missing latitude and longitude for courses"
  task :update_coordinates => :environment do
    puts "Starting to update missing coordinates for courses..."
    
    # Get courses with missing coordinates
    courses_needing_coordinates = Course.where("latitude IS NULL OR longitude IS NULL")
    count = courses_needing_coordinates.count
    
    if count == 0
      puts "No courses found with missing coordinates!"
      exit 0
    end
    
    puts "Found #{count} courses with missing coordinates."
    
    processed = 0
    updated = 0
    
    courses_needing_coordinates.find_each do |course|
      processed += 1
      puts "\nProcessing (#{processed}/#{count}): #{course.name}"
      
      # Check if course has a location with coordinates
      if course.locations.any? { |loc| loc.latitude.present? && loc.longitude.present? }
        location = course.locations.find { |loc| loc.latitude.present? && loc.longitude.present? }
        
        puts "Found location with coordinates: #{location.name} (#{location.latitude}, #{location.longitude})"
        
        # Use GetCourseInfoService to get detailed info including coordinates
        begin
          service = GetCourseInfoService.new(course)
          course_info = service.gather_info
          
          if course.latitude.present? && course.longitude.present?
            updated += 1
            puts "✅ Successfully updated coordinates for course: #{course.name}"
            puts "   New coordinates: (#{course.latitude}, #{course.longitude})"
          else
            puts "❌ Failed to get coordinates for course: #{course.name}"
          end
        rescue => e
          puts "❌ Error processing course #{course.name}: #{e.message}"
        end
      else
        puts "❌ No location with valid coordinates found for course: #{course.name}"
      end
      
      # Add a small delay to avoid hitting API rate limits
      sleep 2
    end
    
    puts "\nCompleted updating coordinates."
    puts "#{updated} out of #{count} courses were successfully updated with coordinates."
  end
end 