class FindLodgingsByCoordinatesService
  def initialize(latitude, longitude, state)
    @latitude = latitude
    @longitude = longitude
    @state = state
    @api_key = if Rails.env.production?
      Rails.application.credentials.google_maps[:api_key]
    else
      Rails.application.credentials.google_maps[:development_api_key]
    end
  end

  def find_lodgings
    puts "\nSearching for lodgings near (#{@latitude}, #{@longitude})"
    
    # Make the API request
    lodging_data = fetch_lodgings_from_google
    return [] if lodging_data.empty?

    # Process each lodging
    lodging_data.each do |data|
      create_lodging_if_in_state(data)
    end
  end

  private

  def fetch_lodgings_from_google
    uri = URI("https://maps.googleapis.com/maps/api/place/nearbysearch/json")
    params = {
      location: "#{@latitude},#{@longitude}",
      radius: 1609, # 1 mile
      type: "lodging",
      key: @api_key
    }

    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    return [] unless data["status"] == "OK"

    puts "Found #{data['results'].size} lodgings in the area"
    data["results"]
  end
  
  def create_lodging_if_in_state(data)
    lodging_lat = data.dig("geometry", "location", "lat")
    lodging_lng = data.dig("geometry", "location", "lng")
    return if Lodging.exists?(google_place_id: data["place_id"])

    place_state = reverse_geocode(lodging_lat, lodging_lng)
  
    unless place_state == @state
      puts "⚠️ Skipping #{data['name']} — located in #{place_state}, not #{@state}"
      return
    end

    state_record = State.find_by(name: @state)
    unless state_record
      puts "❌ State record not found for #{@state}"
      return
    end

    lodging = Lodging.find_or_initialize_by(
      name: data["name"],
      latitude: lodging_lat,
      longitude: lodging_lng
    )

    # Fetch additional details from Google Places API
    place_details = fetch_place_details(data["place_id"])
    return unless place_details

    # Process photo if available
    process_photo(lodging, place_details) if place_details["photos"].present?

    lodging.assign_attributes(
      state_id: state_record.id,
      google_place_id: data["place_id"],
      rating: data["rating"],
      review_count: data["user_ratings_total"],
      price_level: data["price_level"],
      address: data["vicinity"],
      website_url: place_details["website"]
    )
  
    if lodging.save
      puts "✅ Saved #{lodging.name}"
    else
      puts "❌ Error: #{lodging.name}"
      lodging.errors.full_messages.each { |msg| puts "  - #{msg}" }
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

  def process_photo(lodging, place_details)
    return if lodging.image_url.present?
    
    photo_ref = place_details["photos"].first["photo_reference"]
    photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{@api_key}"
    
    begin
      image_file = URI.open(photo_url)
      upload = Cloudinary::Uploader.upload(
        image_file,
        folder: "golf_directory/lodgings",
        public_id: "lodging_#{lodging.id}_#{SecureRandom.hex(4)}",
        resource_type: "image"
      )
      lodging.image_url = upload['secure_url']
    rescue => e
      puts "❌ Error processing photo for #{lodging.name}: #{e.message}"
    end
  end

  def reverse_geocode(lat, lng)
    uri = URI("https://maps.googleapis.com/maps/api/geocode/json")
    params = {
      latlng: "#{lat},#{lng}",
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    data = JSON.parse(response.body)
    return nil unless data["status"] == "OK"
    
    # Find the state component in the address
    address_components = data["results"].first["address_components"]
    state_component = address_components.find { |component| component["types"].include?("administrative_area_level_1") }
    
    state_component&.dig("long_name")
  end
end 