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

  # Initialize the service with an optional location
  # If no location is provided, it can be used for batch processing
  def initialize(location = nil)
    @location = location
    # Use environment-specific API keys
    if Rails.env.production?
      @api_key = Rails.application.credentials.google_maps[:api_key]
    elsif Rails.env.development? || Rails.env.test?
      @api_key = Rails.application.credentials.google_maps[:development_api_key]
    end
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
    return unless @location && @location.latitude && @location.longitude

    begin
      puts "Fetching lodging data for #{@location.name}..."
      lodging_data = fetch_lodging_data
      
      if lodging_data.nil? || lodging_data.empty?
        puts "No lodging data found for #{@location.name}"
        return []
      end

      saved_lodgings = process_lodging_data(lodging_data)
      
      if saved_lodgings.present?
        # Calculate and update the average lodging price for the location
        puts "Updating lodging price for #{@location.name}..."
        update_location_lodging_price(saved_lodgings)
        saved_lodgings
      else
        puts "No lodgings were saved for #{@location.name}"
        []
      end
    rescue StandardError => e
      puts "Error in enrich method: #{e.message}"
      puts e.backtrace.join("\n")
      []
    end
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
      fields: 'name,place_id,geometry,vicinity,formatted_phone_number,website,rating,types,photos'
    }

    puts "Making API request to Google Places API..."
    uri = URI('https://maps.googleapis.com/maps/api/place/nearbysearch/json')
    uri.query = URI.encode_www_form(params.except(:key))

    begin
      response = Net::HTTP.get_response(uri)
      
      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        
        if data['status'] == 'OK'
          puts "Found #{data['results'].size} lodging places"
          
          # Filter out places without ratings
          rated_places = data['results'].select { |place| place['rating'].present? }
          puts "#{rated_places.size} places have ratings"
          
          rated_places
        else
          puts "API Error: #{data['status']}"
          []
        end
      else
        puts "HTTP Error: #{response.code} - #{response.message}"
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

  # Process the lodging data and return summary
  def process_lodging_data(lodging_data)
    return [] unless lodging_data && lodging_data.any?

    puts "Processing lodging data..."
    puts "Total places found: #{lodging_data.size}"

    # Sort by rating (highest first) and take top 5
    sorted_places = lodging_data.sort_by { |place| -place['rating'].to_f }
    top_places = sorted_places.first(5)

    puts "Saving top #{top_places.size} places to database:"
    saved_lodgings = []
    
    top_places.each do |place|
      begin
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
          saved_lodgings << lodging
          puts "- Saved: #{lodging.name} (Rating: #{lodging.rating})"
          
          # Download and attach photo if available (but don't let photo errors stop processing)
          if photo_reference.present?
            begin
              puts "  Downloading photo for #{lodging.name}..."
              lodging.download_photo if lodging.respond_to?(:download_photo)
            rescue StandardError => e
              puts "  Photo download error: #{e.message}"
            end
          end
        else
          puts "- Failed to save: #{lodging.name} - #{lodging.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        puts "Error processing lodging #{place['name']}: #{e.message}"
      end
    end

    puts "Successfully processed #{saved_lodgings.size} lodging options"
    saved_lodgings
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