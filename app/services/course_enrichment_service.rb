# CourseEnrichmentService
#
# This service is responsible for finding and enriching golf course information for a given location
# using the Google Places API. It follows a three-step process:
#
# 1. Search for golf courses near the location
# 2. Filter and sort the results
# 3. Fetch detailed information for each course
#
# The service currently operates in "logging mode" - it finds and displays information but does not
# save it to the database. This allows for testing and verification before implementing the save functionality.
#
# Usage
#   service = CourseEnrichmentService.new(location)
#   service.enrich
#
# Process:
# 1. Initial Search:
#    - Searches for golf courses within a 1-mile radius of the location
#    - Uses the 'golf_course' type filter
#    - Returns only places with ratings
#
# 2. Filtering:
#    - Sorts courses by rating (highest first)
#    - Takes the top 5 rated courses
#
# 3. Detailed Information:
#    - For each course, makes a Place Details API call
#    - Fetches comprehensive information including:
#      - Contact details (phone, website)
#      - Location information
#      - Ratings and reviews
#      - Photos
#      - Opening hours
#      - Price level
#
# Output:
# - Logs the API requests and responses
# - Shows the number of courses found and filtered
# - Displays detailed information for each course
# - Indicates what would be saved to the database
#
# Note: This service is designed to be run via the rake task:
#   rails "course:enrich[Location Name]"

class CourseEnrichmentService
  def initialize(location)
    @location = location
    @api_key = Rails.application.credentials.google_maps[:api_key]
  end

  def enrich
    puts "\nStarting course enrichment for #{@location.name}"
    puts "Location: #{@location.name} (ID: #{@location.id})"
    puts "Coordinates: #{@location.latitude}, #{@location.longitude}"
    
    # Fetch course data from Google Places API
    course_data = fetch_course_data
    return if course_data.empty?

    # Process and log the data
    process_course_data(course_data)
  end

  private

  def fetch_course_data
    params = {
      location: "#{@location.latitude},#{@location.longitude}",
      radius: 1609, # 1 mile radius
      type: 'golf_course',
      key: @api_key
    }

    puts "\nMaking API request to Google Places API..."
    uri = URI('https://maps.googleapis.com/maps/api/place/nearbysearch/json')
    uri.query = URI.encode_www_form(params)
    puts "URL: #{uri}"
    puts "Params: #{params.except(:key)}"

    response = Net::HTTP.get_response(uri)
    puts "Response status: #{response.code}"

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      puts "\nFull API Response:"
      puts JSON.pretty_generate(data)
      
      if data['status'] == 'OK'
        puts "\nTotal results before filtering: #{data['results'].size}"
        
        # Filter out places without ratings
        rated_places = data['results'].select { |place| place['rating'].present? }
        puts "Results after filtering for ratings: #{rated_places.size}"
        
        rated_places
      else
        puts "Error: #{data['status']}"
        nil
      end
    else
      puts "HTTP Error: #{response.code} - #{response.message}"
      nil
    end
  end

  def fetch_course_details(place_id)
    params = {
      place_id: place_id,
      fields: 'name,formatted_address,formatted_phone_number,website,rating,reviews,photos,opening_hours,price_level,types',
      key: @api_key
    }

    puts "\nFetching details for place ID: #{place_id}"
    uri = URI('https://maps.googleapis.com/maps/api/place/details/json')
    uri.query = URI.encode_www_form(params)
    puts "URL: #{uri}"
    puts "Params: #{params.except(:key)}"

    response = Net::HTTP.get_response(uri)
    puts "Response status: #{response.code}"

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      if data['status'] == 'OK'
        puts "Successfully fetched details"
        data['result']
      else
        puts "Error fetching details: #{data['status']}"
        nil
      end
    else
      puts "HTTP Error: #{response.code} - #{response.message}"
      nil
    end
  end

  def process_course_data(course_data)
    return [] unless course_data

    puts "\nProcessing course data..."
    puts "Total places found: #{course_data.size}"

    # Sort by rating (highest first) and take top 5
    sorted_places = course_data.sort_by { |place| -place['rating'] }
    top_places = sorted_places.first(5)

    puts "\nTop 5 courses found:"
    top_places.each_with_index do |place, index|
      puts "\n--- Course #{index + 1} ---"
      puts "Name: #{place['name']}"
      puts "Place ID: #{place['place_id']}"
      puts "Rating: #{place['rating']}"
      puts "Address: #{place['vicinity']}"
      puts "Phone: #{place['formatted_phone_number'] || 'Not available'}"
      puts "Website: #{place['website'] || 'Not available'}"
      puts "Types: #{place['types'].join(', ')}"
      puts "Location: #{place['geometry']['location']['lat']}, #{place['geometry']['location']['lng']}"
      puts "Photo Reference: #{place['photos']&.first&.dig('photo_reference') || 'Not available'}"

      # Fetch detailed information
      details = fetch_course_details(place['place_id'])
      if details
        puts "\nDetailed Information:"
        puts "Full Address: #{details['formatted_address']}"
        puts "Phone: #{details['formatted_phone_number'] || 'Not available'}"
        puts "Website: #{details['website'] || 'Not available'}"
        puts "Price Level: #{details['price_level'] || 'Not available'}"
        puts "Opening Hours: #{details['opening_hours']&.dig('weekday_text')&.join("\n  ") || 'Not available'}"
        puts "Number of Reviews: #{details['reviews']&.size || 0}"
        puts "Types: #{details['types'].join(', ')}"
        puts "Number of Photos: #{details['photos']&.size || 0}"
      end
    end

    puts "\nWould save #{top_places.size} courses to database"
    top_places
  end
end 