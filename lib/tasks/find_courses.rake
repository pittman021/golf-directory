namespace :golf do
  desc "Find golf courses in Las Vegas"
  task find_las_vegas_courses: :environment do
    puts "Starting to find golf courses in Las Vegas..."
    
    # Create or find Las Vegas location
    location = Location.find_or_create_by!(
      name: "Las Vegas",
      state: "Nevada",
      country: "USA",
      region: "West"
    ) do |loc|
      # Set default coordinates for Las Vegas
      loc.latitude = 36.1699
      loc.longitude = -115.1398
    end
    
    puts "\nProcessing location: #{location.name}"
    
    # Use FindCoursesByLocationService to find and enrich courses
    service = FindCoursesByLocationService.new(location)
    service.find_and_enrich
    
    # Update location statistics
    location.update_avg_green_fee
    location.calculate_and_update_trip_cost
    
    puts "\nFound #{location.courses.count} courses in Las Vegas:"
    location.courses.each do |course|
      puts "- #{course.name} (Rating: #{course.average_rating || 'N/A'}, Price Level: #{course.price_level || 'N/A'})"
    end
    
    puts "\nLocation Statistics:"
    puts "- Average Green Fee: $#{location.avg_green_fee || 'N/A'}"
    puts "- Estimated Trip Cost: $#{location.estimated_trip_cost || 'N/A'}"
    
    puts "\nCourse search completed!"
  end

  desc "Find golf courses for a specific location"
  task :find_courses_for_location, [:location_name] => :environment do |t, args|
    if args[:location_name].blank?
      puts "Please specify a location name. Usage: rails golf:find_courses_for_location[location_name]"
      exit
    end

    puts "Starting to find golf courses for #{args[:location_name]}..."
    
    # Find the location
    location = Location.find_by(name: args[:location_name])
    
    if location.nil?
      puts "Location '#{args[:location_name]}' not found in the database."
      exit
    end
    
    puts "\nProcessing location: #{location.name}"
    
    # Use FindCoursesByLocationService to find and enrich courses
    service = FindCoursesByLocationService.new(location)
    service.find_and_enrich
    
    # Update location statistics
    location.update_avg_green_fee
    location.calculate_and_update_trip_cost
    
    puts "\nFound #{location.courses.count} courses in #{location.name}:"
    location.courses.each do |course|
      puts "- #{course.name} (Rating: #{course.average_rating || 'N/A'}, Price Level: #{course.price_level || 'N/A'})"
    end
    
    puts "\nLocation Statistics:"
    puts "- Average Green Fee: $#{location.avg_green_fee || 'N/A'}"
    puts "- Estimated Trip Cost: $#{location.estimated_trip_cost || 'N/A'}"
    
    puts "\nCourse search completed!"
  end
end 