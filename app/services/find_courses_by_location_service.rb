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
    # Use environment-specific API keys
    if Rails.env.production?
      @api_key = Rails.application.credentials.google_maps[:api_key]
    elsif Rails.env.development? || Rails.env.test?
      @api_key = Rails.application.credentials.google_maps[:development_api_key]
    end
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
    keywords = ["golf course", "golf club", "golf resort"]
    radius = 70000 # Increased to 70km radius
    all_results = []

    puts "Making requests to Google Places API..."
    keywords.each do |keyword|
      params = {
        location: "#{@location.latitude},#{@location.longitude}",
        radius: radius,
        keyword: keyword,
        type: "golf_course", # Primary type
        key: @api_key
      }

      puts "\nSearching with parameters:"
      puts "- Location: #{params[:location]}"
      puts "- Radius: #{params[:radius]}m"
      puts "- Keyword: #{params[:keyword]}"
      puts "- Type: #{params[:type]}"

      begin
        uri = URI(BASE_URL)
        uri.query = URI.encode_www_form(params)
        response = Net::HTTP.get_response(uri)
        
        if response.is_a?(Net::HTTPSuccess)
          data = JSON.parse(response.body)
          puts "API Response Status: #{data['status']}"
          puts "Number of results: #{data['results']&.size || 0}"
          
          if data['status'] == 'OK'
            all_results += data['results']
            puts "✅ Successfully found #{data['results'].size} courses with keyword '#{keyword}'"
          else
            puts "⚠️ Google Places API Error: #{data['status']}"
            puts "Error details: #{data['error_message']}" if data['error_message']
          end
        else
          puts "❌ HTTP Error: #{response.code}"
          puts "Response body: #{response.body}"
        end
      rescue JSON::ParserError => e
        puts "❌ Error parsing API response: #{e.message}"
      rescue StandardError => e
        puts "❌ Unexpected error in fetch_courses_from_google with keyword '#{keyword}': #{e.message}"
        puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
      end
    end

    # Deduplicate by place_id
    unique_courses = {}
    all_results.each do |place|
      unique_courses[place['place_id']] ||= place
    end
    deduped_results = unique_courses.values

    # Filter results to ensure they are golf courses
    filtered_courses = deduped_results.select do |place|
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
    
    puts "\n✅ After deduplication and filtering: #{filtered_courses.size} unique golf courses found"
    filtered_courses.first(MAX_RESULTS)
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
        puts "Green Fee: #{course_data['green_fee']}"
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
        # Only set these defaults for new records or if fields are blank
        attributes_to_update = {}
        
        # Always update Google Place data
        attributes_to_update[:google_place_id] = course_data['place_id'] if course_data['place_id'].present?
        
        # For new records or blank fields, set defaults
        if course.new_record?
          attributes_to_update[:course_type] = course_type
          attributes_to_update[:number_of_holes] = 18    # Default to 18 holes
          attributes_to_update[:par] = 72                # Default to par 72
          attributes_to_update[:yardage] = 6500          # Default to 6500 yards
          attributes_to_update[:green_fee] = 100         # Default to $100
          attributes_to_update[:course_tags] = course_data['types'] || [] # Required field
          attributes_to_update[:description] = course_data['vicinity'] if course_data['vicinity'].present?
          attributes_to_update[:website_url] = course_data['website'] if course_data['website'].present?
          attributes_to_update[:notes] = "Automatically imported from Google Places API"
        else
          # For existing records, only update if blank
          attributes_to_update[:course_type] = course_type if course.course_type.blank?
          attributes_to_update[:number_of_holes] = 18 if course.number_of_holes.blank?
          attributes_to_update[:par] = 72 if course.par.blank?
          attributes_to_update[:yardage] = 6500 if course.yardage.blank?
          attributes_to_update[:green_fee] = 100 if course.green_fee.blank?
          attributes_to_update[:course_tags] = course_data['types'] || [] if course.course_tags.blank?
          attributes_to_update[:description] = course_data['vicinity'] if course.description.blank? && course_data['vicinity'].present?
          attributes_to_update[:website_url] = course_data['website'] if course.website_url.blank? && course_data['website'].present?
        end
        
        # Only update the fields that need updating
        course.assign_attributes(attributes_to_update)

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