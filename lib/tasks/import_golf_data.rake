require 'csv'
require 'net/http'
require 'json'

namespace :import do
  desc "Import and enrich golf course data"
  task golf_data: :environment do
    puts "Starting golf data import and enrichment..."
    
    # Track created records for summary
    created_locations = []
    created_courses = []
    
    # Define a limited set of regions and states for testing
    regions = {
      "Northeast" => [
        "Connecticut",
        "Maine",
        "Massachusetts",
        "New Hampshire",
        "New Jersey",
        "New York",
        "Pennsylvania",
        "Rhode Island",
        "Vermont"
      ],
      "Midwest" => [
        "Illinois",
        "Indiana",
        "Iowa",
        "Kansas",
        "Michigan",
        "Minnesota",
        "Missouri",
        "Nebraska",
        "North Dakota",
        "Ohio",
        "South Dakota",
        "Wisconsin"
      ],
      "South" => [
        "Alabama",
        "Arkansas",
        "Delaware",
        "Florida",
        "Georgia",
        "Kentucky",
        "Louisiana",
        "Maryland",
        "Mississippi",
        "North Carolina",
        "Oklahoma",
        "South Carolina",
        "Tennessee",
        "Texas",
        "Virginia",
        "West Virginia"
      ],
      "West" => [
        "Alaska",
        "Arizona",
        "California",
        "Colorado",
        "Hawaii",
        "Idaho",
        "Montana",
        "Nevada",
        "New Mexico",
        "Oregon",
        "Utah",
        "Washington",
        "Wyoming"
      ]
    }

    # Configuration for limits
    MAX_CITIES_PER_STATE = 25  # Maximum number of cities to process per state
    MAX_COURSES_PER_CITY = 25  # Maximum number of courses to process per city
    MIN_COURSES_FOR_LOCATION = 10  # Minimum number of courses needed to create a location

    # Define metropolitan areas and their associated cities
    METROPOLITAN_AREAS = {
      # Northeast
      "New York City" => ["New York", "Brooklyn", "Queens", "Bronx", "Staten Island", "Jersey City", "Newark"],
      "Boston" => ["Boston", "Cambridge", "Somerville", "Brookline", "Newton"],
      "Philadelphia" => ["Philadelphia", "Camden", "Wilmington"],
      
      # Midwest
      "Chicago" => ["Chicago", "Evanston", "Oak Park", "Skokie"],
      "Detroit" => ["Detroit", "Dearborn", "Troy", "Bloomfield Hills"],
      "Minneapolis" => ["Minneapolis", "Saint Paul", "Bloomington", "Edina"],
      
      # South
      "Orlando" => ["Orlando", "Kissimmee", "Lake Buena Vista", "Windermere", "Winter Garden", "Winter Park", "Celebration"],
      "Myrtle Beach" => ["Myrtle Beach", "North Myrtle Beach", "Murrells Inlet", "Pawleys Island"],
      "Dallas" => ["Dallas", "Fort Worth", "Plano", "Irving", "Arlington"],
      "Houston" => ["Houston", "Sugar Land", "The Woodlands", "Katy"],
      "Atlanta" => ["Atlanta", "Sandy Springs", "Alpharetta", "Roswell"],
      
      # West
      "Palm Springs" => ["Palm Springs", "La Quinta", "Indian Wells", "Rancho Mirage", "Cathedral City"],
      "Scottsdale" => ["Scottsdale", "Phoenix", "Tempe", "Mesa"],
      "Las Vegas" => ["Las Vegas", "Henderson", "Summerlin", "North Las Vegas"],
      "San Diego" => ["San Diego", "La Jolla", "Carlsbad", "Encinitas"],
      "Seattle" => ["Seattle", "Bellevue", "Kirkland", "Redmond"],
      "Denver" => ["Denver", "Aurora", "Littleton", "Englewood"],
      "Portland" => ["Portland", "Beaverton", "Lake Oswego", "Tigard"]
    }

    # Retrieve API keys from Rails credentials
    google_api_key = Rails.application.credentials.google_maps[:api_key]
    weather_api_key = Rails.application.credentials.openweathermap_api_key

    # Validate API keys
    unless google_api_key.present?
      puts "Error: Google Maps API key is missing. Please add it to config/credentials.yml.enc under google_maps.api_key"
      exit 1
    end

    regions.each do |region, states|
      puts "\nProcessing region: #{region}"
      
      states.each do |state|
        puts "\nProcessing state: #{state}"
        
        # Step 1: Create a temporary location for the state
        location = Location.create!(
          name: state,
          region: region,
          state: state,
          country: "USA",
          latitude: 0,  # Will be updated with actual coordinates
          longitude: 0  # Will be updated with actual coordinates
        )
        
        # Step 2: Use FindCoursesByLocationService to find and enrich courses
        service = FindCoursesByLocationService.new(location)
        service.find_and_enrich
        
        # Step 3: Update location statistics
        location.update_avg_green_fee
        location.update_estimated_trip_cost
        
        created_locations << location
        created_courses += location.courses.to_a
        
        puts "Processed #{location.courses.count} courses for #{state}"
      end
    end
    
    # Print summary of created records
    puts "\nImport Summary:"
    puts "\nCreated #{created_locations.size} new locations:"
    created_locations.each { |loc| puts "- #{loc.name}" }
    
    puts "\nCreated #{created_courses.size} new courses:"
    created_courses.each { |course| puts "- #{course.name}" }
    
    puts "\nImport completed successfully!"
  end

  private

  # Helper method to extract city name from formatted address
  def self.extract_city(address)
    address.split(',')[1]&.strip
  end

  # Correct city names based on known mappings
  def self.correct_city_name(city)
    corrections = {
      "Newport Coast" => "Newport Beach",
      "Pebble Beach" => "Pebble Beach",
      # Add more corrections as needed
    }
    corrections[city] || city
  end

  # Generate a descriptive text for the course
  def self.generate_course_description(details)
    types = details['types'].join(', ')
    address = details['formatted_address']
    "A #{types} golf course located at #{address}"
  end

  # Determine course type based on Google Places categories
  def self.determine_course_type(types)
    if types.include?('country_club')
      1  # private_course
    elsif types.include?('resort')
      2  # resort_course
    else
      0  # public_course
    end
  end

  # Estimate course yardage based on course type
  def self.calculate_yardage(types)
    if types.include?('championship')
      7000
    elsif types.include?('executive')
      5000
    else
      6000
    end
  end

  # Calculate green fee based on Google Places price level
  def self.calculate_green_fee(price_level)
    case price_level
    when 1 then 50
    when 2 then 100
    when 3 then 150
    when 4 then 200
    else 75
    end
  end

  # Extract relevant tags from Google Places categories
  def self.extract_course_tags(types)
    tags = []
    tags << 'public' if types.include?('golf_course')
    tags << 'resort' if types.include?('resort')
    tags << 'championship' if types.include?('stadium')
    tags << 'executive' if types.include?('executive')
    tags << 'standard' if tags.empty?  # Ensure at least one tag is present
    tags
  end

  # Extract common themes from positive reviews
  def self.extract_course_notes(reviews)
    return nil unless reviews.present?
    
    positive = reviews.select { |r| r['rating'] >= 4 }
    common_themes = positive.map { |r| r['text'] }
                           .join(' ')
                           .downcase
                           .split(/[^a-z]+/)
                           .group_by(&:itself)
                           .transform_values(&:count)
                           .sort_by { |_, v| -v }
                           .first(5)
                           .map(&:first)
    
    "Commonly praised for: #{common_themes.join(', ')}"
  end

  # Estimate average lodging cost based on city size
  def self.calculate_average_lodging(city)
    case city
    when /new york|los angeles|chicago|houston|phoenix|philadelphia|san antonio|san diego|dallas|san jose/i
      200
    when /austin|jacksonville|fort worth|columbus|charlotte|san francisco|indianapolis|seattle|denver|washington/i
      150
    else
      100
    end
  end

  # Find the metropolitan area for a given city
  def self.find_metropolitan_area(city)
    METROPOLITAN_AREAS.each do |metro, cities|
      return metro if cities.include?(city)
    end
    nil
  end
end 