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
          puts "- Layout tags: #{course.layout_tags.join(', ')}"
          
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
end 