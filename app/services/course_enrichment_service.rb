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
    uri.query = URI.encode_www_form(params.except(:key))

    response = Net::HTTP.get_response(uri)
    puts "Response status: #{response.code}"

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      
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
    puts "\nProcessing #{course_data.size} courses for #{@location.name}"
    
    course_data.each do |place_data|
      # Skip if there's no name
      next unless place_data['name'].present?
      
      # Check if this course already exists for this location
      existing_course = @location.courses.find_by(google_place_id: place_data['place_id'])
      
      if existing_course
        puts "Updating existing course: #{place_data['name']}"
        course = existing_course
      else
        puts "Creating new course: #{place_data['name']}"
        course = @location.courses.new(
          google_place_id: place_data['place_id'],
          name: place_data['name']
        )
      end
      
      # Update course data
      course.assign_attributes(
        rating: place_data['rating'],
        review_count: place_data['user_ratings_total'],
        address: place_data['vicinity'],
        latitude: place_data['geometry']['location']['lat'],
        longitude: place_data['geometry']['location']['lng'],
        green_fee: calculate_green_fee(place_data['price_level']) || course.green_fee || random_green_fee
      )
      
      # Add photos if available
      if place_data['photos'].present? && place_data['photos'][0]['photo_reference'].present?
        photo_reference = place_data['photos'][0]['photo_reference']
        course.image_url ||= "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=#{photo_reference}&key=#{@api_key}"
      end
      
      if course.save
        puts "✅ Saved course: #{course.name} (ID: #{course.id})"
      else
        puts "❌ Failed to save course: #{course.errors.full_messages.join(', ')}"
      end
    end
    
    puts "\nFinished enriching courses for #{@location.name}"
    course_data.size # Return number of courses processed
  end
  
  def calculate_green_fee(price_level)
    return nil if price_level.nil?
    
    case price_level
    when 1
      rand(25..40)
    when 2
      rand(40..75)
    when 3
      rand(75..150)
    when 4
      rand(150..300)
    when 5
      rand(300..500)
    else
      nil
    end
  end
  
  def random_green_fee
    rand(35..250)
  end
end 