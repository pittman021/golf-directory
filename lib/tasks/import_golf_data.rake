require 'csv'
require 'net/http'
require 'json'

namespace :import do
  desc "Import golf locations and courses using Google Places API and OpenWeatherMap"
  task golf_data: :environment do
    puts "Starting golf data import..."
    
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

    # Process each region and its states
    regions.each do |region, states|
      puts "\nProcessing region: #{region}"
      
      states.each do |state|
        puts "\nProcessing state: #{state}"
        
        # Step 1: Fetch golf courses from Google Places API
        uri = URI("https://maps.googleapis.com/maps/api/place/textsearch/json")
        params = {
          query: "golf course in #{state}",
          type: "golf_course",
          key: google_api_key
        }
        uri.query = URI.encode_www_form(params)
        
        puts "Fetching courses from Google Places API..."
        puts "Request URL: #{uri.to_s}"
        
        begin
          response = Net::HTTP.get_response(uri)
          puts "Response status: #{response.code}"
          puts "Response body: #{response.body}" if response.code != "200"
          
          if response.is_a?(Net::HTTPSuccess)
            data = JSON.parse(response.body)
            
            if data['status'] != 'OK'
              puts "Google Places API Error: #{data['status']}"
              puts "Error message: #{data['error_message']}" if data['error_message']
              next
            end
            
            courses = data['results']
            puts "Found #{courses.size} courses in #{state}"
            
            if courses.empty?
              puts "No courses found. Trying alternative search..."
              params = {
                query: "golf club in #{state}",
                type: "golf_course",
                key: google_api_key
              }
              uri.query = URI.encode_www_form(params)
              
              puts "Alternative request URL: #{uri.to_s}"
              response = Net::HTTP.get_response(uri)
              
              if response.is_a?(Net::HTTPSuccess)
                data = JSON.parse(response.body)
                if data['status'] == 'OK'
                  courses = data['results']
                  puts "Found #{courses.size} courses with alternative search"
                else
                  puts "Alternative search failed: #{data['status']}"
                  next
                end
              end
            end
            
            # Step 2: Group courses by city and check for existing locations
            courses_by_city = courses.group_by { |c| extract_city(c['formatted_address']) }
            puts "Grouped into #{courses_by_city.size} cities"
            
            # Group courses by metropolitan area
            courses_by_metro = {}
            courses_by_city.each do |city, city_courses|
              metro_area = find_metropolitan_area(city)
              if metro_area
                courses_by_metro[metro_area] ||= []
                courses_by_metro[metro_area] += city_courses
              else
                courses_by_metro[city] ||= []
                courses_by_metro[city] += city_courses
              end
            end
            
            puts "Grouped into #{courses_by_metro.size} metropolitan areas"
            
            # Sort metropolitan areas by number of courses and take top MAX_CITIES_PER_STATE
            top_metros = courses_by_metro.sort_by { |_, courses| -courses.size }.first(MAX_CITIES_PER_STATE)
            puts "Processing top #{MAX_CITIES_PER_STATE} metropolitan areas with most courses"
            
            # Process each metropolitan area and its courses
            top_metros.each do |metro, metro_courses|
              puts "\nProcessing metropolitan area: #{metro} (#{metro_courses.size} courses)"
              
              # Check if location already exists
              location = Location.find_by("LOWER(name) = LOWER(?)", metro)
              if location
                puts "Location already exists: #{location.name}"
              else
                # Only create new location if there are enough courses to form a cluster
                if metro_courses.size >= MIN_COURSES_FOR_LOCATION
                  # Calculate average coordinates for the metropolitan area
                  avg_lat = metro_courses.sum { |c| c['geometry']['location']['lat'] } / metro_courses.size
                  avg_lng = metro_courses.sum { |c| c['geometry']['location']['lng'] } / metro_courses.size
                  
                  location = Location.create!(
                    name: metro,
                    region: region,
                    state: state,
                    country: "USA",
                    latitude: avg_lat,
                    longitude: avg_lng
                  )
                  created_locations << location
                  puts "Created new location: #{location.name}"
                else
                  puts "Skipping location creation - not enough courses (#{metro_courses.size}) to form a significant cluster (minimum #{MIN_COURSES_FOR_LOCATION} required)"
                  next
                end
              end
              
              # Get weather data
              weather_uri = URI("https://api.openweathermap.org/data/2.5/weather")
              weather_params = {
                lat: metro_courses.first['geometry']['location']['lat'],
                lon: metro_courses.first['geometry']['location']['lng'],
                appid: weather_api_key,
                units: 'imperial'
              }
              weather_uri.query = URI.encode_www_form(weather_params)
              
              weather_response = Net::HTTP.get_response(weather_uri)
              if weather_response.is_a?(Net::HTTPSuccess)
                weather_data = JSON.parse(weather_response.body)
                location.update!(
                  average_temp: weather_data['main']['temp'],
                  conditions: weather_data['weather'].first['description']
                )
              end
              
              # Get airport data - only take the first airport
              airports_uri = URI("https://maps.googleapis.com/maps/api/place/nearbysearch/json")
              airports_params = {
                location: "#{metro_courses.first['geometry']['location']['lat']},#{metro_courses.first['geometry']['location']['lng']}",
                radius: 50000,
                type: 'airport',
                key: google_api_key
              }
              airports_uri.query = URI.encode_www_form(airports_params)
              
              airports_response = Net::HTTP.get_response(airports_uri)
              if airports_response.is_a?(Net::HTTPSuccess)
                airports_data = JSON.parse(airports_response.body)
                if airports_data['status'] == 'OK' && airports_data['results'].any?
                  location.update!(nearest_airports: airports_data['results'].first['name'])
                end
              end
              
              # Process each course, limited to MAX_COURSES_PER_CITY
              metro_courses.first(MAX_COURSES_PER_CITY).each do |course_data|
                details_uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
                details_params = {
                  place_id: course_data['place_id'],
                  fields: 'name,formatted_address,website,price_level,reviews,types',
                  key: google_api_key
                }
                details_uri.query = URI.encode_www_form(details_params)
                
                details_response = Net::HTTP.get_response(details_uri)
                if details_response.is_a?(Net::HTTPSuccess)
                  details = JSON.parse(details_response.body)['result']
                  
                  # Check if course already exists
                  course = Course.find_by(
                    name: details['name'],
                    latitude: course_data['geometry']['location']['lat'],
                    longitude: course_data['geometry']['location']['lng']
                  )
                  
                  if course
                    puts "Course already exists: #{course.name}"
                  else
                    course = Course.create!(
                      name: details['name'],
                      latitude: course_data['geometry']['location']['lat'],
                      longitude: course_data['geometry']['location']['lng'],
                      description: generate_course_description(details),
                      course_type: determine_course_type(details['types']),
                      number_of_holes: 18,
                      par: 72,
                      yardage: calculate_yardage(details['types']),
                      green_fee: calculate_green_fee(details['price_level']),
                      website_url: details['website'] || '',
                      layout_tags: extract_course_tags(details['types']).presence || ['standard'],
                      notes: extract_course_notes(details['reviews'])
                    )
                    created_courses << course
                    puts "Created new course: #{course.name}"
                  end
                  
                  # Create location-course association if it doesn't exist
                  unless LocationCourse.exists?(location: location, course: course)
                    LocationCourse.create!(location: location, course: course)
                    puts "Created association between #{location.name} and #{course.name}"
                  end
                else
                  puts "Failed to get course details: #{details_response.code}"
                end
              end
            end
          else
            puts "Error fetching courses for #{state}: #{response.code}"
            puts "Response body: #{response.body}"
          end
        rescue StandardError => e
          puts "Error processing #{state}: #{e.message}"
          puts e.backtrace.join("\n")
        end
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