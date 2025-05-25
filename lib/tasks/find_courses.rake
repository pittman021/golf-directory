# This file contains Rake tasks for finding and processing golf courses by location.
# 
# Tasks included:

# - golf:get_courses_for_all_states: Finds and processes golf courses for all 50 states
# - golf:get_courses_by_state[state_name]: Finds and processes golf courses for a specified state
# - golf:find_courses_for_location[location_name]: Finds and processes golf courses for a specific location

require_relative "../golf_data/state_coordinates"

namespace :golf do
  desc "Seed golf courses for a state using multiple centerpoints"
  task :get_courses_by_state, [:state_name] => :environment do |_, args|
    state = args[:state_name]
    unless GolfData::StateCoordinates[state]
      puts "❌ No coordinates found for #{state}. Add it to GolfData::StateCoordinates."
      exit
    end

    puts "📍 Starting seed for #{state}..."
    GolfData::StateCoordinates[state].each_with_index do |coord, i|
      puts "🔄 Point ##{i + 1} (#{coord[:lat]}, #{coord[:lng]})"
      FindCoursesByCoordinatesService.new(
        lat: coord[:lat],
        lng: coord[:lng],
        state: state
      ).find_and_seed
    end
    puts "✅ Finished seeding courses for #{state}!"
  end

  desc "Seed courses for all 50 states"
  task :get_courses_for_all_states => :environment do
    GolfData::StateCoordinates.each_key do |state|
      Rake::Task["golf:get_courses_by_state"].invoke(state)
      Rake::Task["golf:get_courses_by_state"].reenable
    end
  end

  desc "Find courses near Ponte Vedra Beach"
  task :find_ponte_vedra_courses => :environment do
    puts "📍 Starting search for courses near Ponte Vedra Beach..."
    
    # Ponte Vedra Beach coordinates
    lat = 30.2394
    lng = -81.3857
    
    FindCoursesByCoordinatesService.new(
      lat: lat,
      lng: lng,
      state: "Florida"
    ).find_and_seed
    
    puts "✅ Finished finding courses near Ponte Vedra Beach!"
  end

  desc "Find and associate courses for a specific location"
  task :find_courses_for_location, [:location_name] => :environment do |_, args|
    location_name = args[:location_name]
    
    # Find the location in the database
    location = Location.find_by(name: location_name)
    if location.nil?
      puts "❌ Location '#{location_name}' not found in database!"
      exit
    end

    # Check if location has coordinates
    unless location.latitude.present? && location.longitude.present?
      puts "❌ Location '#{location_name}' does not have coordinates set!"
      exit
    end

    puts "📍 Starting search for courses near #{location_name}..."
    puts "📍 Using coordinates: (#{location.latitude}, #{location.longitude})"
    
    # Find courses using the coordinates service
    service = FindCoursesByCoordinatesService.new(
      lat: location.latitude,
      lng: location.longitude,
      state: location.state
    )
    
    # Fetch courses from Google Places API
    courses_data = service.find_and_seed
    
    if courses_data.any?
      puts "\n✅ Found #{courses_data.size} potential courses near #{location_name}"
      
      # Process each course
      courses_data.each do |course_data|
        begin
          # Get detailed place information
          place_details = service.fetch_place_details(course_data['place_id'])
          next unless place_details

          # Create or find the course
          course = Course.find_or_initialize_by(
            name: course_data['name'],
            latitude: course_data['geometry']['location']['lat'],
            longitude: course_data['geometry']['location']['lng']
          )

          # Update course attributes
          course.assign_attributes(
            google_place_id: course_data['place_id'],
            course_type: service.determine_course_type(course_data['types']),
            course_tags: course_data['types'] || [],
            phone_number: place_details['formatted_phone_number'],
            website_url: place_details['website'],
            description: place_details['editorial_summary']&.dig('overview') || course_data['vicinity']
          )

          # Set default values for new records
          if course.new_record?
            course.assign_attributes(
              number_of_holes: 18,
              par: 72,
              yardage: 6500,
              green_fee: 100,
              notes: "Automatically imported from Google Places API"
            )
          end

          # Save the course
          if course.save
            # Associate with location if not already associated
            unless location.courses.include?(course)
              location.courses << course
              puts "✅ Created and associated #{course.name} with #{location_name}"
            else
              puts "ℹ️ #{course.name} is already associated with #{location_name}"
            end
          else
            puts "❌ Failed to save course #{course.name}: #{course.errors.full_messages.join(', ')}"
          end
        rescue StandardError => e
          puts "❌ Error processing course #{course_data['name']}: #{e.message}"
        end
      end
    else
      puts "ℹ️ No courses found near #{location_name}"
    end
    
    puts "\n✅ Finished processing courses for #{location_name}!"
  end
end
