class LodgingEnrichmentService
  # Custom error classes for better error handling
  class APIError < StandardError; end
  class InvalidResponseError < StandardError; end
  class RateLimitError < StandardError; end

  # Initialize the service with an optional location
  # If no location is provided, it can be used for batch processing
  def initialize(location)
    @location = location
    @api_key = Rails.application.credentials.google_maps[:api_key]
    @base_url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
  end

  # Process all locations in the database
  # Returns an array of results for each processed location
  def enrich_all_locations
    results = []
    # Use find_each to process locations in batches to avoid memory issues
    Location.find_each do |location|
      @location = location
      result = enrich
      results << result if result
    end

    results
  end

  # Process a single location to enrich its lodging data
  def enrich
    return unless @location.latitude && @location.longitude

    lodging_data = fetch_lodging_data
    return if lodging_data.empty?

    process_lodging_data(lodging_data)
  end

  private

  # Fetch lodging data from Google Places API
  # Makes a single API call with optimized parameters
  def fetch_lodging_data
    params = {
      location: "#{@location.latitude},#{@location.longitude}",
      radius: 1609, # 1 mile radius
      type: 'lodging',
      key: @api_key,
      fields: 'name,place_id,geometry,vicinity,formatted_phone_number,website,rating,types,photos' # Add photos to fields
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

  # Process the lodging data and return summary
  def process_lodging_data(lodging_data)
    return [] unless lodging_data

    puts "\nProcessing lodging data..."
    puts "Total places found: #{lodging_data.size}"

    # Sort by rating (highest first) and take top 5
    sorted_places = lodging_data.sort_by { |place| -place['rating'] }
    top_places = sorted_places.first(5)

    puts "\nSaving top 5 places to database:"
    saved_lodgings = []
    
    top_places.each do |place|
      # Try to find existing lodging or create new one
      lodging = Lodging.find_or_initialize_by(google_place_id: place['place_id'])
      
      # Get photo reference if available
      photo_reference = place['photos']&.first&.dig('photo_reference')
      
      # Update attributes
      lodging.assign_attributes(
        location: @location,
        name: place['name'],
        latitude: place['geometry']['location']['lat'],
        longitude: place['geometry']['location']['lng'],
        formatted_address: place['vicinity'],
        formatted_phone_number: place['formatted_phone_number'],
        website: place['website'],
        rating: place['rating'],
        types: place['types'],
        research_status: 'pending',
        research_attempts: 0,
        photo_reference: photo_reference
      )

      if lodging.save
        # Download and attach photo if available
        if photo_reference.present?
          puts "  Downloading photo for #{lodging.name}..."
          lodging.download_photo
          puts "  Photo #{lodging.photo.attached? ? 'successfully downloaded' : 'download failed'}"
        end

        saved_lodgings << lodging
        puts "- #{lodging.new_record? ? 'Created' : 'Updated'}: #{lodging.name} (Rating: #{lodging.rating})"
      else
        puts "- Failed to save: #{lodging.name} - #{lodging.errors.full_messages.join(', ')}"
      end
    end

    puts "\nSuccessfully processed #{saved_lodgings.size} lodging options"
    saved_lodgings
  end

  # Categorize lodging types for better organization
  # Currently not used but kept for potential future use
  def categorize_lodging_type(types)
    if types.include?('resort')
      'resort'
    elsif types.include?('bed_and_breakfast')
      'bed_and_breakfast'
    elsif types.include?('hotel')
      'hotel'
    else
      'other'
    end
  end
end