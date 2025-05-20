# app/services/find_courses_by_coordinates_service.rb
require 'uri'
require 'open-uri'

class FindCoursesByCoordinatesService
    def initialize(lat:, lng:, state:)
      @lat = lat
      @lng = lng
      @state = state
      @api_key = Rails.application.credentials.google_maps[:development_api_key]
    end
  
    def find_and_seed
      courses = fetch_courses
      courses.each { |data| create_course_if_in_state(data) }
    end
  
    private
  
    def fetch_courses
      uri = URI("https://maps.googleapis.com/maps/api/place/nearbysearch/json")
      params = {
        location: "#{@lat},#{@lng}",
        radius: 70000,
        keyword: "golf course",
        type: "golf_course",
        key: @api_key
      }
      uri.query = URI.encode_www_form(params)
      res = Net::HTTP.get_response(uri)
      data = JSON.parse(res.body)


      return data["results"] || []
    end
  
    def create_course_if_in_state(data)
      course_lat = data.dig("geometry", "location", "lat")
      course_lng = data.dig("geometry", "location", "lng")
      return if Course.exists?(google_place_id: data["place_id"])
  
      place_state = reverse_geocode(course_lat, course_lng)
    
      unless place_state == @state
        puts "⚠️ Skipping #{data['name']} — located in #{place_state}, not #{@state}"
        return
      end

      state_record = State.find_by(name: @state)
      unless state_record
        puts "❌ State record not found for #{@state}"
        return
      end
  
      course = Course.find_or_initialize_by(
        name: data["name"],
        latitude: course_lat,
        longitude: course_lng
      )

      # Fetch additional details from Google Places API
      place_details = fetch_place_details(data["place_id"])
      return unless place_details

      # Process photo if available
      process_photo(course, place_details) if place_details["photos"].present?
  
      course.assign_attributes(
        state_id: state_record.id,
        google_place_id: data["place_id"],
        green_fee: 75,
        course_type: determine_course_type(place_details["types"]),
        number_of_holes: 18,
        par: 72,
        yardage: 6500,
        course_tags: place_details["types"] || ["public"],
        notes: "Seeded by state grid",
        website_url: place_details["website"],
        description: place_details["formatted_address"]
      )
    
      if course.save
        puts "✅ Saved #{course.name}"
      else
        puts "❌ Error: #{course.name}"
        course.errors.full_messages.each { |msg| puts "  - #{msg}" }
      end
    end

    def fetch_place_details(place_id)
      uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
      params = {
        place_id: place_id,
        fields: 'name,formatted_address,formatted_phone_number,website,rating,reviews,photos,opening_hours,price_level,types',
        key: @api_key
      }
      uri.query = URI.encode_www_form(params)
      
      response = Net::HTTP.get_response(uri)
      return unless response.is_a?(Net::HTTPSuccess)
      
      data = JSON.parse(response.body)
      return data["result"] if data["status"] == "OK"
      nil
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
        puts "❌ Error processing photo for #{course.name}: #{e.message}"
      end
    end


    def determine_course_type(types)
      return :public_course unless types.present?
      
      if types.include?("country_club")
        :private_course
      elsif types.include?("resort")
        :resort_course
      else
        :public_course
      end
    end
  
    def reverse_geocode(lat, lng)
      uri = URI("https://maps.googleapis.com/maps/api/geocode/json")
      uri.query = URI.encode_www_form(latlng: "#{lat},#{lng}", key: @api_key)
      response = Net::HTTP.get_response(uri)
      return unless response.is_a?(Net::HTTPSuccess)
  
      data = JSON.parse(response.body)
      component = data["results"]&.flat_map { |r| r["address_components"] }&.find do |c|
        c["types"].include?("administrative_area_level_1")
      end
  
      component&.dig("long_name")
    end
  end