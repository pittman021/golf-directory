# FindCoursesByLocationService
#
# This service is responsible for finding golf courses near a specific location
# using the Google Places API and enriching them with detailed information.
#
# Process:
# 1. Takes a location and finds nearby golf courses using Google Places API
# 2. For each course found, uses GetCourseInfoService to gather detailed information
# 3. Creates or updates course records in the database
#
# Usage:
#   service = FindCoursesByLocationService.new(location)
#   service.find_and_enrich
# 
# Note: This service requires:
# - A valid location record in the database
# - Google Places API credentials
# - OpenAI API credentials

class FindCoursesByLocationService
  BASE_URL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
  MAX_RESULTS = 20

  def initialize(location)
    @location = location
    @api_key = Rails.application.credentials.google_maps[:api_key]
  end

  def find_and_enrich
    return unless @location.present?

    puts "\nFinding courses near #{@location.name}..."
    begin
      courses = fetch_courses_from_google
      if courses.empty?
        puts "⚠️ No courses found for #{@location.name}"
        return
      end

      puts "Found #{courses.size} courses. Enriching with detailed information..."
      enrich_courses(courses)
    rescue StandardError => e
      puts "❌ Error in find_and_enrich: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
    end
  end

  private

  def fetch_courses_from_google
    params = {
      location: "#{@location.latitude},#{@location.longitude}",
      radius: 50000, # Increased to 50km radius
      keyword: "golf course",  # Primary keyword
      type: "golf_course",     # Primary type
      key: @api_key
    }

    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(params)

    puts "Making request to Google Places API..."
    puts "Search parameters:"
    puts "- Location: #{params[:location]}"
    puts "- Radius: #{params[:radius]}m"
    puts "- Keyword: #{params[:keyword]}"
    puts "- Type: #{params[:type]}"

    begin
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        puts "API Response Status: #{data['status']}"
        puts "Number of results: #{data['results']&.size || 0}"
        
        if data['status'] == 'OK'
          # Filter results to ensure they are golf courses
          courses = data['results'].first(MAX_RESULTS).select do |place|
            types = place['types'] || []
            name = place['name'].downcase
            
            # More inclusive filtering criteria
            (types.include?('golf_course') || 
             types.include?('country_club') || 
             name.include?('golf') ||
             name.include?('club') ||
             name.include?('course')) && 
            !types.include?('store') && 
            !types.include?('shopping_mall') &&
            !types.include?('supermarket')
          end
          
          puts "✅ Successfully found #{courses.size} courses"
          courses
        else
          puts "⚠️ Google Places API Error: #{data['status']}"
          puts "Error details: #{data['error_message']}" if data['error_message']
          puts "Full response: #{data.inspect}"
          []
        end
      else
        puts "❌ HTTP Error: #{response.code}"
        puts "Response body: #{response.body}"
        []
      end
    rescue JSON::ParserError => e
      puts "❌ Error parsing API response: #{e.message}"
      []
    rescue StandardError => e
      puts "❌ Unexpected error in fetch_courses_from_google: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
      []
    end
  end

  def enrich_courses(courses)
    courses.each do |course_data|
      begin
        # Log the raw course data for debugging
        puts "\nRaw course data:"
        puts "Name: #{course_data['name']}"
        puts "Place ID: #{course_data['place_id']}"
        puts "Types: #{course_data['types'].join(', ')}"
        puts "Rating: #{course_data['rating']}"
        puts "Price Level: #{course_data['price_level']}"
        puts "Vicinity: #{course_data['vicinity']}"

        # Find or create the course
        course = Course.find_or_initialize_by(
          name: course_data['name'],
          latitude: course_data['geometry']['location']['lat'],
          longitude: course_data['geometry']['location']['lng']
        )

        # Determine course type based on Google Places categories
        course_type = determine_course_type(course_data['types'])

        # Set required fields with default values if not available
        course.assign_attributes(
          course_type: course_type,
          number_of_holes: 18,    # Default to 18 holes (validated to be 9 or 18)
          par: 72,                # Default to par 72 (validated as integer)
          yardage: 6500,          # Default to 6500 yards (validated as integer)
          green_fee: 100,         # Default to $100 (validated as >= 0)
          layout_tags: course_data['types'] || [], # Required field
          description: course_data['vicinity'],    # Optional field
          website_url: course_data['website'],     # Optional field
          notes: "Automatically imported from Google Places API" # Optional field
        )

        if course.save
          # Associate with location if not already
          unless course.locations.include?(@location)
            course.locations << @location
            puts "✅ Successfully associated #{course.name} with #{@location.name}"
          end
          puts "✅ Successfully saved course: #{course.name}"
        else
          puts "❌ Failed to save course #{course.name}:"
          course.errors.full_messages.each do |error|
            puts "  - #{error}"
          end
        end

      rescue StandardError => e
        puts "❌ Error processing course #{course_data['name']}: #{e.message}"
        puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
      end
    end
  end

  def determine_course_type(types)
    if types.include?('country_club')
      :private_course
    elsif types.include?('resort')
      :resort_course
    else
      :public_course
    end
  end
end 