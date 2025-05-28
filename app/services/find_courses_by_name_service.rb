# FindCoursesByNameService
#
# This service is responsible for finding golf courses by name
# using the Google Places API.
#
# Process:
# 1. Takes a name and finds matching golf courses using Google Places API
# 2. Creates or updates course records with detailed information
#
# Usage:
#   service = FindCoursesByNameService.new(name)
#   courses = service.find_and_create
# 
# Note: This service requires:
# - Google Places API credentials

class FindCoursesByNameService
  BASE_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
  MAX_RESULTS = 20

  def initialize(name)
    @name = name
    # Use environment-specific API keys
    if Rails.env.production?
      @api_key = Rails.application.credentials.google_maps[:api_key]
    elsif Rails.env.development? || Rails.env.test?
      @api_key = Rails.application.credentials.google_maps[:development_api_key]
    end
  end

  def find_and_create
    return [] unless @name.present?

    puts "\nFinding courses matching '#{@name}'..."
    begin
      courses = fetch_courses_from_google
      if courses.empty?
        puts "⚠️ No courses found matching '#{@name}'"
        return []
      end

      puts "Found #{courses.size} courses. Creating/updating records..."
      created_courses = create_or_update_courses(courses)
      created_courses
    rescue StandardError => e
      puts "❌ Error in find_and_create: #{e.message}"
      puts "Backtrace: #{e.backtrace.first(5).join("\n")}"
      []
    end
  end

  private

  def fetch_courses_from_google
    keywords = ["golf course", "golf club", "golf resort"]
    all_results = []

    puts "Making requests to Google Places API..."
    keywords.each do |keyword|
      params = {
        query: "#{@name} #{keyword}",
        type: "golf_course", # Primary type
        key: @api_key
      }

      puts "\nSearching with parameters:"
      puts "- Query: #{params[:query]}"
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

  def create_or_update_courses(courses)
    created_courses = []
    
    courses.each do |course_data|
      begin
        # Log the raw course data for debugging
        puts "\nProcessing course data:"
        puts "Name: #{course_data['name']}"
        puts "Place ID: #{course_data['place_id']}"
        puts "Types: #{course_data['types'].join(', ')}"

        # Get detailed place information including photos
        if course_data['place_id'].present?
          begin
            detailed_info = fetch_place_details(course_data['place_id'])
            if detailed_info.present?
              course_data.merge!(detailed_info)
              puts "✅ Retrieved detailed information"
            end
          rescue StandardError => e
            puts "⚠️ Error fetching detailed info: #{e.message}"
          end
        end

        # Find or initialize course
        course = Course.find_or_initialize_by(
          name: course_data['name'],
          latitude: course_data['geometry']['location']['lat'],
          longitude: course_data['geometry']['location']['lng']
        )

        # Determine course type
        course_type = determine_course_type(course_data['types'])

        # Build attributes to update (only using attributes that exist on Course model)
        attributes = {
          google_place_id: course_data['place_id'],
          course_type: course_type,
          course_tags: course_data['types'] || [],
          website_url: course_data['website'],
          description: course_data['editorial_summary']&.dig('overview') || course_data['vicinity']
        }

        # Handle photos if present
        if course_data['photos'].present?
          photo_reference = course_data['photos'].first['photo_reference']
          attributes[:image_url] = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=#{photo_reference}&key=#{@api_key}"
        end

        # Set default values for new records
        if course.new_record?
          attributes.merge!({
            number_of_holes: 18,    # Default to 18 holes
            par: 72,                # Default to par 72
            yardage: 6500,         # Default to 6500 yards
            green_fee: 100,        # Default to $100
            notes: "Automatically imported from Google Places API",
            state_id: find_or_create_state_from_address(course_data['formatted_address'] || course_data['vicinity'])
          })
        end

        # Update attributes and save
        course.assign_attributes(attributes)

        if course.save
          created_courses << course
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

    created_courses
  end

  def fetch_place_details(place_id)
    uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
    params = {
      place_id: place_id,
      fields: 'name,formatted_address,website,rating,reviews,photos,opening_hours,price_level,types,editorial_summary',
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)
    
    data = JSON.parse(response.body)
    return data["result"] if data["status"] == "OK"
    nil
  end

  def find_or_create_state_from_address(address)
    return 1 unless address.present? # Default to first state if no address
    
    # Extract state from address (assuming US format)
    state_match = address.match(/,\s*([A-Z]{2})\s*\d{5}/) || address.match(/,\s*([A-Za-z\s]+),?\s*USA?/)
    
    if state_match
      state_name = state_match[1].strip
      # Handle abbreviations
      state_name = case state_name.upcase
                   when 'CA' then 'California'
                   when 'NY' then 'New York'
                   when 'FL' then 'Florida'
                   when 'TX' then 'Texas'
                   when 'GA' then 'Georgia'
                   when 'NC' then 'North Carolina'
                   when 'SC' then 'South Carolina'
                   when 'NJ' then 'New Jersey'
                   when 'PA' then 'Pennsylvania'
                   when 'MA' then 'Massachusetts'
                   when 'IL' then 'Illinois'
                   when 'OH' then 'Ohio'
                   when 'MI' then 'Michigan'
                   when 'WI' then 'Wisconsin'
                   when 'OR' then 'Oregon'
                   when 'WA' then 'Washington'
                   when 'AZ' then 'Arizona'
                   when 'NV' then 'Nevada'
                   when 'CO' then 'Colorado'
                   when 'UT' then 'Utah'
                   when 'NM' then 'New Mexico'
                   when 'WY' then 'Wyoming'
                   when 'MT' then 'Montana'
                   when 'ID' then 'Idaho'
                   when 'ND' then 'North Dakota'
                   when 'SD' then 'South Dakota'
                   when 'NE' then 'Nebraska'
                   when 'KS' then 'Kansas'
                   when 'OK' then 'Oklahoma'
                   when 'AR' then 'Arkansas'
                   when 'LA' then 'Louisiana'
                   when 'MS' then 'Mississippi'
                   when 'AL' then 'Alabama'
                   when 'TN' then 'Tennessee'
                   when 'KY' then 'Kentucky'
                   when 'WV' then 'West Virginia'
                   when 'VA' then 'Virginia'
                   when 'MD' then 'Maryland'
                   when 'DE' then 'Delaware'
                   when 'CT' then 'Connecticut'
                   when 'RI' then 'Rhode Island'
                   when 'VT' then 'Vermont'
                   when 'NH' then 'New Hampshire'
                   when 'ME' then 'Maine'
                   when 'AK' then 'Alaska'
                   when 'HI' then 'Hawaii'
                   else state_name
                   end
      
      state = State.find_by(name: state_name)
      return state&.id || 1 # Return state ID or default to 1
    end
    
    1 # Default to first state
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