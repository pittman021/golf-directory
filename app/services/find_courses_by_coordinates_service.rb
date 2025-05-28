# app/services/find_courses_by_coordinates_service.rb
require 'uri'
require 'open-uri'

class FindCoursesByCoordinatesService
    def initialize(lat:, lng:, state:)
      @lat = lat
      @lng = lng
      @state = state
      @api_key = if Rails.env.production?
        Rails.application.credentials.google_maps[:api_key]
      else
        Rails.application.credentials.google_maps[:development_api_key]
      end
      @processed_place_ids = Set.new
    end
  
    def find_and_seed
      puts "🔍 Starting comprehensive search for #{@state} at (#{@lat}, #{@lng})"
      
      total_courses_found = 0
      
      # Enhanced search strategies optimized for efficiency and effectiveness
      search_strategies = [
        # Core strategies - these find the most courses
        { keyword: "golf course", type: "golf_course", radius: 100000 }, # Primary strategy - most productive
        { keyword: "country club", type: "golf_course", radius: 100000 }, # Private/exclusive courses - very productive
      ]
      
      search_strategies.each_with_index do |strategy, index|
        puts "  📍 Strategy #{index + 1}/#{search_strategies.length}: '#{strategy[:keyword]}' (#{strategy[:radius]/1000}km radius)"
        
        courses = fetch_courses_with_pagination(strategy)
        strategy_count = 0
        
        courses.each do |course_data|
          next if @processed_place_ids.include?(course_data["place_id"])
          @processed_place_ids.add(course_data["place_id"])
          
          if create_course_if_in_state(course_data)
            strategy_count += 1
            total_courses_found += 1
          end
        end
        
        puts "    ✅ Found #{strategy_count} new courses with this strategy"
        
        # Early termination: if we've found 5+ courses and completed the first strategy, 
        # we can skip remaining strategies for efficiency in areas with many courses
        if total_courses_found >= 5 && index >= 0 # After first strategy
          puts "    🚀 Early termination: Found #{total_courses_found} courses, skipping remaining strategies for efficiency"
          break
        end
        
        # Rate limiting - be respectful to Google's API
        sleep(1) unless index == search_strategies.length - 1
      end
      
      puts "🏁 Total new courses found for #{@state}: #{total_courses_found}"
      total_courses_found
    end
  
    private
    
    def fetch_courses_with_pagination(strategy)
      all_courses = []
      next_page_token = nil
      page_count = 0
      max_pages = 2 # Reduced from 3 for efficiency - most relevant courses in first 2 pages
      
      loop do
        page_count += 1
        puts "    📄 Fetching page #{page_count}..."
        
        courses_page = fetch_courses_page(strategy, next_page_token)
        break if courses_page.empty?
        
        all_courses.concat(courses_page[:results])
        next_page_token = courses_page[:next_page_token]
        
        puts "    📊 Page #{page_count}: #{courses_page[:results].length} results"
        
        # Break if no more pages or reached max pages
        break if next_page_token.nil? || page_count >= max_pages
        
        # Google requires a short delay before using next_page_token
        sleep(2)
      end
      
      puts "    📋 Total results across #{page_count} pages: #{all_courses.length}"
      all_courses
    end
    
    def fetch_courses_page(strategy, page_token = nil)
      uri = URI("https://maps.googleapis.com/maps/api/place/nearbysearch/json")
      params = {
        location: "#{@lat},#{@lng}",
        radius: strategy[:radius],
        keyword: strategy[:keyword],
        type: strategy[:type],
        key: @api_key
      }
      
      params[:pagetoken] = page_token if page_token
      
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        
        unless response.is_a?(Net::HTTPSuccess)
          puts "    ❌ HTTP Error: #{response.code} #{response.message}"
          return { results: [], next_page_token: nil }
        end
        
        data = JSON.parse(response.body)
        
        case data["status"]
        when "OK"
          return {
            results: data["results"] || [],
            next_page_token: data["next_page_token"]
          }
        when "ZERO_RESULTS"
          puts "    ℹ️ No results for this search"
          return { results: [], next_page_token: nil }
        when "OVER_QUERY_LIMIT"
          puts "    ⚠️ API quota exceeded - stopping search"
          return { results: [], next_page_token: nil }
        when "REQUEST_DENIED"
          puts "    ❌ API request denied - check API key"
          return { results: [], next_page_token: nil }
        when "INVALID_REQUEST"
          puts "    ❌ Invalid request parameters"
          return { results: [], next_page_token: nil }
        else
          puts "    ⚠️ Unexpected API status: #{data['status']}"
          return { results: [], next_page_token: nil }
        end
        
      rescue JSON::ParserError => e
        puts "    ❌ JSON parsing error: #{e.message}"
        return { results: [], next_page_token: nil }
      rescue StandardError => e
        puts "    ❌ Network error: #{e.message}"
        return { results: [], next_page_token: nil }
      end
    end
  
    def create_course_if_in_state(data)
      course_lat = data.dig("geometry", "location", "lat")
      course_lng = data.dig("geometry", "location", "lng")
      
      # Skip if we already have this course
      if Course.exists?(google_place_id: data["place_id"])
        puts "    ⏭️ Skipping #{data['name']} - already exists"
        return false
      end
      
      # Filter out non-traditional golf courses
      unless is_valid_golf_course?(data["name"], data["types"])
        puts "    🚫 Skipping #{data['name']} - not a traditional golf course"
        return false
      end
      
      # Enhanced state verification with multiple validation methods
      place_state = verify_course_state(course_lat, course_lng, data)
      unless place_state == @state
        puts "    🗺️ Skipping #{data['name']} - located in #{place_state}, not #{@state}"
        return false
      end

      state_record = State.find_by(name: @state)
      unless state_record
        puts "    ❌ State record not found for #{@state}"
        return false
      end
  
      course = Course.find_or_initialize_by(
        name: data["name"],
        latitude: course_lat,
        longitude: course_lng
      )

      # Fetch additional details from Google Places API
      place_details = fetch_place_details(data["place_id"])
      return false unless place_details

      # Process photo if available
      process_photo(course, place_details) if place_details["photos"].present?
      
      # Enhanced course type determination
      course_type = determine_course_type(place_details["types"], data["name"], place_details)
      
      # Better default values based on course type
      default_values = get_default_values_by_type(course_type)
  
      course.assign_attributes(
        state_id: state_record.id,
        google_place_id: data["place_id"],
        course_type: course_type,
        course_tags: place_details["types"] || ["public"],
        notes: generate_notes(place_details),
        website_url: place_details["website"],
        phone: place_details["formatted_phone_number"],
        description: generate_description(place_details, data),
        **default_values
      )
    
      if course.save
        puts "    ✅ Saved #{course.name} (#{course_type})"
        
        # Log Google's pricing and rating data for future reference
        if place_details["rating"] || place_details["price_level"] || place_details["user_ratings_total"]
          puts "    📊 Google Data:"
          puts "      Rating: #{place_details['rating']}/5 (#{place_details['user_ratings_total']} reviews)" if place_details['rating']
          puts "      Price Level: #{place_details['price_level']}/4 #{price_level_description(place_details['price_level'])}" if place_details['price_level']
          puts "      Website: #{place_details['website'] ? 'Yes' : 'No'}"
        end
        
        return true
      else
        puts "    ❌ Error saving #{course.name}: #{course.errors.full_messages.join(', ')}"
        return false
      end
    end

    def fetch_place_details(place_id)
      uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
      params = {
        place_id: place_id,
        fields: 'name,formatted_address,formatted_phone_number,website,rating,user_ratings_total,reviews,photos,opening_hours,price_level,types,editorial_summary',
        key: @api_key
      }
      uri.query = URI.encode_www_form(params)
      
      begin
        response = Net::HTTP.get_response(uri)
        return nil unless response.is_a?(Net::HTTPSuccess)
        
        data = JSON.parse(response.body)
        return data["result"] if data["status"] == "OK"
        
        puts "    ⚠️ Place details error: #{data['status']}"
        nil
      rescue StandardError => e
        puts "    ❌ Error fetching place details: #{e.message}"
        nil
      end
    end

    def process_photo(course, place_details)
      return if course.image_url.present?
      
      photo_ref = place_details["photos"].first["photo_reference"]
      photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{@api_key}"
      
      begin
        image_file = URI.open(photo_url)
        upload = Cloudinary::Uploader.upload(
          image_file,
          folder: "golf_directory/courses",
          public_id: "course_#{course.id}_#{SecureRandom.hex(4)}",
          resource_type: "image"
        )
        course.image_url = upload['secure_url']
      rescue => e
        puts "    ⚠️ Photo processing failed for #{course.name}: #{e.message}"
      end
    end

    def determine_course_type(types, name, place_details)
      return :public_course unless types.present?
      
      name_lower = name.downcase
      
      # Check for private/exclusive indicators
      if types.include?("country_club") || 
         name_lower.include?("country club") || 
         name_lower.include?("private") ||
         name_lower.include?("members only")
        return :private_course
      end
      
      # Check for resort indicators
      if types.include?("resort") || 
         types.include?("lodging") ||
         name_lower.include?("resort") ||
         name_lower.include?("hotel")
        return :resort_course
      end
      
      # Check for municipal indicators
      if name_lower.include?("municipal") ||
         name_lower.include?("city") ||
         name_lower.include?("county") ||
         name_lower.include?("public")
        return :public_course
      end
      
      # Default to public
      :public_course
    end
    
    def get_default_values_by_type(course_type)
      case course_type
      when :private_course
        {
          number_of_holes: 18,
          par: 72,
          yardage: 6800,
          green_fee: 150
        }
      when :resort_course
        {
          number_of_holes: 18,
          par: 72,
          yardage: 6600,
          green_fee: 125
        }
      when :public_course
        {
          number_of_holes: 18,
          par: 72,
          yardage: 6400,
          green_fee: 75
        }
      else
        {
          number_of_holes: 18,
          par: 72,
          yardage: 6500,
          green_fee: 100
        }
      end
    end
    
    def generate_description(place_details, data)
      # Try multiple sources for description
      description = place_details.dig("editorial_summary", "overview")
      description ||= place_details["formatted_address"]
      description ||= data["vicinity"]
      description ||= "Golf course in #{@state}"
      
      description
    end

    def generate_notes(place_details)
      notes = ["Automatically imported from Google Places API"]
      notes << "Rating: #{place_details['rating']}/5" if place_details['rating']
      notes << "Reviews: #{place_details['user_ratings_total']}" if place_details['user_ratings_total']
      notes << "Price Level: #{place_details['price_level']}/4" if place_details['price_level']
      notes.join(' | ')
    end

    def price_level_description(price_level)
      case price_level
      when 0
        "(Free)"
      when 1
        "(Inexpensive)"
      when 2
        "(Moderate)"
      when 3
        "(Expensive)"
      when 4
        "(Very Expensive)"
      else
        ""
      end
    end
  
    def verify_course_state(lat, lng, course_data)
      # Method 1: Use reverse geocoding (primary method)
      geocoded_state = reverse_geocode(lat, lng)
      
      # Method 2: Check formatted address from course data if available
      address_state = nil
      if course_data["vicinity"]
        address_state = extract_state_from_address(course_data["vicinity"])
      end
      
      # Method 3: Use place details formatted address as backup
      if geocoded_state.nil? && address_state.nil?
        place_details = fetch_place_details(course_data["place_id"])
        if place_details && place_details["formatted_address"]
          address_state = extract_state_from_address(place_details["formatted_address"])
        end
      end
      
      # Return the most reliable result
      result_state = geocoded_state || address_state
      
      # Log the verification process for debugging
      puts "    🔍 State verification: Geocoded=#{geocoded_state}, Address=#{address_state}, Final=#{result_state}"
      
      result_state
    end
    
    def extract_state_from_address(address)
      return nil unless address
      
      # Common state abbreviations and full names mapping
      state_mappings = {
        'AL' => 'Alabama', 'AK' => 'Alaska', 'AZ' => 'Arizona', 'AR' => 'Arkansas',
        'CA' => 'California', 'CO' => 'Colorado', 'CT' => 'Connecticut', 'DE' => 'Delaware',
        'FL' => 'Florida', 'GA' => 'Georgia', 'HI' => 'Hawaii', 'ID' => 'Idaho',
        'IL' => 'Illinois', 'IN' => 'Indiana', 'IA' => 'Iowa', 'KS' => 'Kansas',
        'KY' => 'Kentucky', 'LA' => 'Louisiana', 'ME' => 'Maine', 'MD' => 'Maryland',
        'MA' => 'Massachusetts', 'MI' => 'Michigan', 'MN' => 'Minnesota', 'MS' => 'Mississippi',
        'MO' => 'Missouri', 'MT' => 'Montana', 'NE' => 'Nebraska', 'NV' => 'Nevada',
        'NH' => 'New Hampshire', 'NJ' => 'New Jersey', 'NM' => 'New Mexico', 'NY' => 'New York',
        'NC' => 'North Carolina', 'ND' => 'North Dakota', 'OH' => 'Ohio', 'OK' => 'Oklahoma',
        'OR' => 'Oregon', 'PA' => 'Pennsylvania', 'RI' => 'Rhode Island', 'SC' => 'South Carolina',
        'SD' => 'South Dakota', 'TN' => 'Tennessee', 'TX' => 'Texas', 'UT' => 'Utah',
        'VT' => 'Vermont', 'VA' => 'Virginia', 'WA' => 'Washington', 'WV' => 'West Virginia',
        'WI' => 'Wisconsin', 'WY' => 'Wyoming'
      }
      
      # Split address into parts
      address_parts = address.split(',').map(&:strip)
      
      # Look for state abbreviation (usually second to last part)
      address_parts.each do |part|
        # Check for state abbreviation
        state_abbrev = part.match(/\b([A-Z]{2})\b/)
        if state_abbrev && state_mappings[state_abbrev[1]]
          return state_mappings[state_abbrev[1]]
        end
        
        # Check for full state name
        state_mappings.values.each do |state_name|
          if part.downcase.include?(state_name.downcase)
            return state_name
          end
        end
      end
      
      nil
    end
  
    def reverse_geocode(lat, lng)
      uri = URI("https://maps.googleapis.com/maps/api/geocode/json")
      uri.query = URI.encode_www_form(latlng: "#{lat},#{lng}", key: @api_key)
      
      begin
        response = Net::HTTP.get_response(uri)
        return nil unless response.is_a?(Net::HTTPSuccess)
    
        data = JSON.parse(response.body)
        
        # Enhanced state extraction - look through all results for the most accurate match
        data["results"]&.each do |result|
          result["address_components"]&.each do |component|
            if component["types"].include?("administrative_area_level_1")
              return component["long_name"]
            end
          end
        end
        
        nil
      rescue StandardError => e
        puts "    ⚠️ Reverse geocoding failed: #{e.message}"
        nil
      end
    end
    
    def is_valid_golf_course?(name, types)
      name_lower = name.downcase
      
      # Exclude disc golf courses
      return false if name_lower.include?("disc")
      
      # Exclude mini golf / putt putt
      return false if name_lower.include?("mini golf")
      return false if name_lower.include?("miniature golf")
      return false if name_lower.include?("putt putt")
      return false if name_lower.include?("putt-putt")
      return false if name_lower.include?("putting course")
      return false if name_lower.include?("adventure golf")
      
      # Exclude driving ranges only (unless they also mention course/club)
      if name_lower.include?("driving range") && 
         !name_lower.include?("golf course") && 
         !name_lower.include?("golf club") &&
         !name_lower.include?("country club")
        return false
      end
      
      # Exclude golf simulators
      return false if name_lower.include?("simulator")
      return false if name_lower.include?("indoor golf")
      
      # Exclude golf stores/shops
      return false if name_lower.include?("golf shop")
      return false if name_lower.include?("golf store")
      return false if name_lower.include?("pro shop") && !name_lower.include?("golf course")
      
      # Exclude restaurants/bars that happen to have golf in the name
      if (name_lower.include?("restaurant") || name_lower.include?("bar") || name_lower.include?("grill")) &&
         !name_lower.include?("golf course") && 
         !name_lower.include?("golf club") &&
         !name_lower.include?("country club")
        return false
      end
      
      # Exclude golf cart services
      return false if name_lower.include?("golf cart")
      
      # Must contain golf-related terms to be considered
      golf_terms = ["golf course", "golf club", "country club", "golf resort", "municipal golf", "public golf", "private golf"]
      has_golf_term = golf_terms.any? { |term| name_lower.include?(term) }
      
      # If no explicit golf terms, check if it's just "golf" with course indicators
      unless has_golf_term
        has_golf_term = name_lower.include?("golf") && 
                       (name_lower.include?("course") || 
                        name_lower.include?("club") || 
                        name_lower.include?("links") ||
                        types&.include?("golf_course"))
      end
      
      has_golf_term
    end
  end