# LodgingEnrichmentService
#
# This service enriches a location with nearby lodging information using the Google Places API.
# It fetches lodging data within a 1-mile radius of the location, sorts by rating,
# and adds the top 5 lodging options to the database. It also calculates and updates
# the average lodging price for the location.
#
# == Usage Examples
#
# 1. Enrich a single location:
#    
#    location = Location.find(123)
#    service = LodgingEnrichmentService.new(location)
#    lodgings = service.enrich
#    # => Returns array of lodging records that were created/updated
#
# 2. Enrich all locations in the database:
#    
#    service = LodgingEnrichmentService.new(nil)  # Nil for batch processing
#    results = service.enrich_all_locations
#    # => Returns array of results for all locations
#
# 3. Run via rake task:
#    
#    $ rails lodging:enrich_all         # Process all locations
#    $ rails lodging:enrich[location_id] # Process a specific location
#
# 4. View lodgings for a location:
#    
#    location = Location.find(123)
#    lodgings = location.lodgings
#    # => Returns ActiveRecord::Relation of lodging objects
#
# == API Requirements
#
# Requires a valid Google Maps API key configured in Rails credentials:
# google_maps:
#   api_key: YOUR_API_KEY
#
# == Data Flow
#
# 1. Location coordinates (lat/long) are sent to Google Places API
# 2. API returns lodging data within the specified radius
# 3. Service filters and sorts results by rating
# 4. Top lodgings are saved to the database
# 5. Photos are downloaded and attached to lodging records
# 6. Average lodging price is calculated and updated for the location

class LodgingEnrichmentService
  # Custom error classes for better error handling
  class APIError < StandardError; end
  class InvalidResponseError < StandardError; end
  class RateLimitError < StandardError; end

  # Default search radius in meters
  # 5 miles = 8047 meters
  # 10 miles = 16093 meters
  DEFAULT_RADIUS = 16093 # 10 miles

  def self.fetch_and_update_lodging_image(lodging)
    return unless lodging.google_place_id.present?
    return if lodging.image_url.present? && lodging.image_url.include?('cloudinary')

    if Rails.env.production?
      api_key = Rails.application.credentials.google_maps[:api_key]
    elsif Rails.env.development? || Rails.env.test?
      api_key = Rails.application.credentials.google_maps[:development_api_key]
    end
  
    # Step 1: Fetch photo_reference if we don't have it
    uri = URI('https://maps.googleapis.com/maps/api/place/details/json')
    uri.query = URI.encode_www_form({
      place_id: lodging.google_place_id,
      fields: 'photos',
      key: api_key
    })
  
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)
  
    data = JSON.parse(response.body)
    photo_ref = data.dig('result', 'photos', 0, 'photo_reference')
    return unless photo_ref
  
    # Step 2: Get image from Google Places Photo API
    photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
    
    begin
      image_file = URI.open(photo_url)
      puts "Fetched image for #{lodging.name}"
    rescue OpenURI::HTTPError => e
      puts "Failed to fetch image from Google: #{e.message}"
      return
    end
  
    # Step 3: Upload to Cloudinary with optimized settings
    begin
      upload = Cloudinary::Uploader.upload(
        image_file,
        folder: "golf_directory/lodgings",
        public_id: "lodging_#{lodging.id}_#{SecureRandom.hex(4)}",
        resource_type: "image",
        quality: "auto:good", # Automatic quality optimization
        fetch_format: "auto", # Automatic format optimization
        secure: true # Use HTTPS
      )
      
      # Step 4: Save final Cloudinary image URL and update timestamp
      lodging.update(
        image_url: upload['secure_url'],
        updated_at: Time.current
      )
      
      puts "✓ Uploaded image to Cloudinary for #{lodging.name}"
    rescue Cloudinary::Error => e
      puts "Failed to upload to Cloudinary: #{e.message}"
    end
  end

  def self.fetch_and_store_place_id(lodging)
    return if lodging.google_place_id.present?

    query = [lodging.name, lodging.location&.name, "lodging"].compact.join(" ")
    puts "🔎 Searching for: #{query}"

    api_key = if Rails.env.production?
      Rails.application.credentials.google_maps[:api_key]
    else
      Rails.application.credentials.google_maps[:development_api_key]
    end

    search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
    search_url.query = URI.encode_www_form({
      input: query,
      inputtype: "textquery",
      fields: "place_id",
      key: api_key
    })

    response = Net::HTTP.get_response(search_url)
    return unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)

    place_id = data.dig("candidates", 0, "place_id")

    if place_id
      lodging.update!(google_place_id: place_id)
      puts "✅ Stored place_id for #{lodging.name}"
      true
    else
      puts "⚠️ No match for #{lodging.name}"
      false
    end
  rescue => e
    puts "❌ Error fetching place_id for #{lodging.name}: #{e.message}"
    false
  end

  # Initialize the service with an optional location
  # If no location is provided, it can be used for batch processing
  def initialize(location = nil, options = {})
    @location = location
    @radius = options[:radius] || DEFAULT_RADIUS
    
    # Use environment-specific API keys
    if Rails.env.production?
      @api_key = Rails.application.credentials.google_maps[:api_key]
    elsif Rails.env.development? || Rails.env.test?
      @api_key = Rails.application.credentials.google_maps[:development_api_key]
    end

    raise APIError, "Missing Google Maps API key" unless @api_key.present?
    puts "Initialized with API key: #{@api_key[0..5]}..." if @api_key.present?
    
    @base_url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
  end

  # Process all locations in the database
  # Returns an array of results for each processed location
  def enrich_all_locations
    results = []
    # Use find_each to process locations in batches to avoid memory issues
    Location.find_each do |location|
      begin
        @location = location
        puts "\nProcessing location: #{location.name}"
        
        result = enrich
        
        # Create result hash with location info
        if result && result.any?
          results << {
            location: location.name,
            lodgings_count: result.size,
            lodging_price_range: location.lodging_price_range,
            avg_lodging_cost: location.avg_lodging_cost_per_night,
            estimated_trip_cost: location.estimated_trip_cost
          }
          puts "Successfully processed #{location.name}"
        else
          puts "No lodgings found for #{location.name}"
        end
      rescue StandardError => e
        puts "Error processing #{location.name}: #{e.message}"
        # Continue with next location even if this one fails
      end
    end

    puts "\nEnrichment complete! Processed #{results.size} locations."
    results
  end

  # Process a single location to enrich its lodging data
  def enrich
    puts "\nStarting lodging enrichment for #{@location.name}"
    puts "Location: #{@location.name} (ID: #{@location.id})"
    
    # Fetch lodging data from Google Places API
    lodging_data = fetch_lodging_data
    return if lodging_data.empty?

    # Process and log the data
    process_lodging_data(lodging_data)
  end

  private

  # Remove all query parameters from URL
  def clean_url(url)
    return nil if url.blank?
    url.split('?').first
  end

  # Fetch lodging data from Google Places API
  # Makes a single API call with optimized parameters
  def fetch_lodging_data
    params = {
      location: "#{@location.latitude},#{@location.longitude}",
      radius: @radius,
      type: 'lodging',
      key: @api_key
    }
    
    uri = URI('https://maps.googleapis.com/maps/api/place/nearbysearch/json')
    uri.query = URI.encode_www_form(params)
    
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        puts "\nAPI Response Status: #{data['status']}"
        puts "Error Message: #{data['error_message']}" if data['error_message']
        
        if data['status'] == 'OK'
          puts "\nTotal results before filtering: #{data['results'].size}"
          
          # Filter out places without ratings
          rated_places = data['results'].select { |place| place['rating'].present? }
          puts "Results after filtering for ratings: #{rated_places.size}"
          
          rated_places
        else
          puts "API Error: #{data['status']}"
          puts "Full response: #{data.inspect}"
          []
        end
      else
        puts "HTTP Error: #{response.code} - #{response.message}"
        puts "Response body: #{response.body}"
        []
      end
    rescue JSON::ParserError => e
      puts "Error parsing API response: #{e.message}"
      []
    rescue StandardError => e
      puts "Error making API request: #{e.message}"
      []
    end
  end

  # Fetch detailed place information using Place Details API
  def fetch_place_details(place_id)
    uri = URI('https://maps.googleapis.com/maps/api/place/details/json')
    params = {
      place_id: place_id,
      fields: 'name,formatted_address,formatted_phone_number,website,url,price_level,rating,user_ratings_total',
      key: @api_key
    }
    uri.query = URI.encode_www_form(params)

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        if data['status'] == 'OK'
          data['result']

          puts data['result']
        else
          puts "Place Details API Error: #{data['status']} for place_id: #{place_id}"
          nil
        end
      else
        puts "HTTP Error fetching place details: #{response.code} - #{response.message}"
        nil
      end
    rescue StandardError => e
      puts "Error fetching place details: #{e.message}"
      nil
    end
  end

  # Process the lodging data and return summary
  def process_lodging_data(lodging_data)
    lodging_data.each do |place_data|
      # Skip if there's no name
      next unless place_data['name'].present?
      
      # Fetch additional details using Place Details API
      place_details = fetch_place_details(place_data['place_id'])
      
      # Check if this lodging already exists for this location
      existing_lodging = @location.lodgings.find_by(google_place_id: place_data['place_id'])
      
      if existing_lodging
        puts "Updating existing lodging: #{place_data['name']}"
        lodging = existing_lodging
      else
        puts "Creating new lodging: #{place_data['name']}"
        lodging = @location.lodgings.new(
          google_place_id: place_data['place_id'],
          name: place_data['name']
        )
      end
      
      # Merge data from both APIs, preferring Place Details when available
      lodging.assign_attributes(
        rating: place_details&.dig('rating') || place_data['rating'],
        types: place_data['types'] || [],
        formatted_address: place_details&.dig('formatted_address') || place_data['vicinity'],
        formatted_phone_number: place_details&.dig('formatted_phone_number'),
        latitude: place_data.dig('geometry', 'location', 'lat'),
        longitude: place_data.dig('geometry', 'location', 'lng'),
        website: clean_url(place_details&.dig('website')),
        research_status: 'completed',
        research_last_attempted: Time.current,
        research_attempts: (lodging.research_attempts || 0) + 1
      )
      
      # Add photos if available
      if place_data['photos'].present? && place_data['photos'][0]['photo_reference'].present?
        photo_reference = place_data['photos'][0]['photo_reference']
        lodging.image_url ||= "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=#{photo_reference}&key=#{@api_key}"
      end
      
      if lodging.save
        puts "✅ Saved lodging: #{lodging.name} (ID: #{lodging.id})"
        # Always try to fetch and update the image after saving
        begin
          self.class.fetch_and_update_lodging_image(lodging)
          puts "  ✓ Updated image for #{lodging.name}"
        rescue => e
          puts "  ⚠️ Failed to update image for #{lodging.name}: #{e.message}"
        end
      else
        puts "❌ Failed to save lodging: #{lodging.errors.full_messages.join(', ')}"
      end
    end
    
    puts "\nFinished enriching lodgings for #{@location.name}"
    lodging_data.size # Return number of lodgings processed
  end

  # Update location with average lodging price
  def update_location_lodging_price(lodgings)
    return if lodgings.empty?
    
    puts "Estimating lodging prices..."
    estimated_prices = []
    
    lodgings.each do |lodging|
      begin
        # Use LodgePriceEstimatorService to get price estimates for each lodging
        estimator = LodgePriceEstimatorService.new(lodging)
        price_estimate = estimator.estimate_price
        
        if price_estimate.present? && price_estimate[:min] && price_estimate[:max]
          min_price = price_estimate[:min].to_i
          max_price = price_estimate[:max].to_i
          avg_price = (min_price + max_price) / 2
          estimated_prices << avg_price
          puts "- #{lodging.name}: $#{min_price}-$#{max_price} (avg: $#{avg_price})"
        else
          puts "- No valid price estimate for #{lodging.name}"
        end
      rescue StandardError => e
        puts "Error estimating price for #{lodging.name}: #{e.message}"
      end
    end
    
    # Calculate average price across all lodgings
    if estimated_prices.present?
      avg_price = (estimated_prices.sum / estimated_prices.size).to_i
      min_price = estimated_prices.min
      max_price = estimated_prices.max
      
      puts "Updating location #{@location.name} with:"
      puts "- Price range: $#{min_price}-$#{max_price}"
      puts "- Average cost per night: $#{avg_price}"
      
      # Update all price-related attributes in a single call
      @location.update(
        lodging_price_min: min_price,
        lodging_price_max: max_price,
        lodging_price_last_updated: Time.current,
        avg_lodging_cost_per_night: avg_price
      )
      
      # The before_save callback will calculate estimated_trip_cost
      puts "Updated #{@location.name} with avg_lodging_cost_per_night: $#{avg_price}"
      puts "Estimated trip cost: $#{@location.estimated_trip_cost}"
      
      true
    else
      puts "No valid price estimates for any lodgings in #{@location.name}"
      false
    end
  end

  # Categorize lodging types for better organization
  def categorize_lodging_type(types)
    return 'unknown' unless types.is_a?(Array)
    
    if types.include?('resort')
      'resort'
    elsif types.include?('bed_and_breakfast')
      'bed_and_breakfast'
    elsif types.include?('hotel')
      'hotel'
    elsif types.include?('lodging')
      'general_lodging'
    else
      'other'
    end
  end
end