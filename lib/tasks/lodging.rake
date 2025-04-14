# This rake task provides focused enrichment for lodging data only.
# It uses LodgingEnrichmentService to:
# - Search for lodging options within 1-mile radius
# - Update lodging prices and availability
# - Process lodging-specific data
#
# Usage:
#   rails lodging:find_and_enrich[location_name]  # Find and enrich a specific location by name
#   rails lodging:find_and_enrich_all             # Find and enrich all locations
#   rails lodging:enrich[location_id]             # Enrich a specific location by ID
#   rails lodging:enrich_all                      # Enrich all locations
#   rails lodging:list[location_name]             # List lodgings for a location
#
# Examples:
#   rails lodging:find_and_enrich["Pebble Beach"]
#   rails lodging:list["Pebble Beach"]
#
# This task is useful for:
# - Quick lodging-only updates
# - Testing lodging API functionality
# - Managing API rate limits
# - Isolating lodging-related issues
#
# Note: This task is not necessary if you're using golf:enrich_destinations,
# which already includes lodging enrichment. Use this for focused updates
# when you don't need to regenerate all destination data.

namespace :lodging do
  desc "Find and enrich lodging data for all locations"
  task find_and_enrich_all: :environment do
    puts "Starting comprehensive lodging enrichment for all locations..."
    
    Location.find_each do |location|
      puts "\nProcessing #{location.name}..."
      
      # Step 1: Find lodging data
      puts "Finding lodging options..."
      enrichment_service = LodgingEnrichmentService.new(location)
      lodgings = enrichment_service.enrich
      
      if lodgings.any?
        puts "Found #{lodgings.size} lodging options"
        
        # Step 2: Get price estimates
        puts "Estimating prices..."
        price_estimates = lodgings.map do |lodge|
          begin
            estimator = LodgePriceEstimatorService.new(lodge)
            estimate = estimator.estimate_price
            
            # Validate the estimate
            if estimate.is_a?(Hash) && estimate[:min].is_a?(Numeric) && estimate[:max].is_a?(Numeric)
              # Update the lodge's research status
              lodge.complete_price_research(estimate)
              puts "  #{lodge.name}: $#{estimate[:min]}-$#{estimate[:max]}"
              estimate
            else
              puts "  Invalid price estimate for #{lodge.name}: #{estimate.inspect}"
              nil
            end
          rescue => e
            puts "  Error estimating price for #{lodge.name}: #{e.message}"
            nil
          end
        end.compact
        
        if price_estimates.any?
          # Calculate min and max from all estimates
          min_price = price_estimates.map { |e| e[:min] }.min
          max_price = price_estimates.map { |e| e[:max] }.max
          
          # Update location with price range
          location.update_lodging_prices(
            min: min_price,
            max: max_price,
            source: 'ChatGPT Estimate',
            notes: "Based on analysis of #{price_estimates.size} lodging options"
          )
          
          # Update estimated trip cost
          location.calculate_estimated_trip_cost
          location.save
          
          puts "\nUpdated #{location.name}:"
          puts "- Lodging Options: #{lodgings.size}"
          puts "- Lodging Price Range: $#{min_price}-$#{max_price}"
          puts "- Estimated Trip Cost: $#{location.estimated_trip_cost}"
        else
          puts "  No valid price estimates were obtained for any lodgings"
        end
      else
        puts "No lodgings found for #{location.name}"
      end
    end
    
    puts "\nEnrichment complete!"
  end

  desc "Find and enrich lodging data for a specific location"
  task :find_and_enrich, [:location_name] => :environment do |t, args|
    if args[:location_name].blank?
      puts "Please provide a location name"
      puts "Usage: rails lodging:find_and_enrich[Pebble Beach]"
      exit
    end
    
    location = Location.find_by(name: args[:location_name])
    if location.nil?
      puts "Error: Location not found"
      exit
    end
    
    puts "\nProcessing #{location.name}..."
    
    # Step 1: Find lodging data
    puts "Finding lodging options..."
    enrichment_service = LodgingEnrichmentService.new(location)
    lodgings = enrichment_service.enrich
    
    if lodgings.any?
      puts "Found #{lodgings.size} lodging options:"
      lodgings.each do |lodge|
        puts "- #{lodge.name} (Rating: #{lodge.rating})"
      end
      
      # Step 2: Get price estimates
      puts "\nEstimating prices..."
      price_estimates = lodgings.map do |lodge|
        begin
          estimator = LodgePriceEstimatorService.new(lodge)
          estimate = estimator.estimate_price
          
          # Validate the estimate
          if estimate.is_a?(Hash) && estimate[:min].is_a?(Numeric) && estimate[:max].is_a?(Numeric)
            # Update the lodge's research status
            lodge.complete_price_research(estimate)
            puts "  #{lodge.name}: $#{estimate[:min]}-$#{estimate[:max]}"
            estimate
          else
            puts "  Invalid price estimate for #{lodge.name}: #{estimate.inspect}"
            nil
          end
        rescue => e
          puts "  Error estimating price for #{lodge.name}: #{e.message}"
          nil
        end
      end.compact
      
      if price_estimates.any?
        # Calculate min and max from all estimates
        min_price = price_estimates.map { |e| e[:min] }.min
        max_price = price_estimates.map { |e| e[:max] }.max
        
        # Update location with price range
        location.update_lodging_prices(
          min: min_price,
          max: max_price,
          source: 'ChatGPT Estimate',
          notes: "Based on analysis of #{price_estimates.size} lodging options"
        )
        
        # Update estimated trip cost
        location.calculate_estimated_trip_cost
        location.save
        
        puts "\nUpdated #{location.name}:"
        puts "- Lodging Options: #{lodgings.size}"
        puts "- Lodging Price Range: $#{min_price}-$#{max_price}"
        puts "- Estimated Trip Cost: $#{location.estimated_trip_cost}"
      else
        puts "  No valid price estimates were obtained for any lodgings"
      end
    else
      puts "No lodgings found for #{location.name}"
    end
  end

  desc "Enrich all locations with lodging data"
  task enrich_all: :environment do
    puts "Starting lodging enrichment for all locations..."
    
    service = LodgingEnrichmentService.new
    results = service.enrich_all_locations
    
    puts "\nEnrichment complete!"
    puts "Processed #{results.size} locations"
    
    results.each do |result|
      puts "\n#{result[:location]}"
      puts "Lodging Price Range: #{result[:lodging_price_range]}"
      puts "Estimated Trip Cost: $#{result[:estimated_trip_cost]}"
    end
  end
  
  desc "Enrich a specific location with lodging data"
  task :enrich, [:location_name] => :environment do |t, args|
    if args[:location_name].blank?
      puts "Please provide a location name"
      puts "Usage: rails lodging:enrich[Pebble Beach]"
      exit
    end
    
    location = Location.find_by(name: args[:location_name])
    if location.nil?
      puts "Error: Location not found"
      exit
    end
    
    service = LodgingEnrichmentService.new(location)
    result = service.enrich
    
    if result
      puts "\nEnrichment complete!"
      puts "Location: #{location.name}"
    else
      puts "Failed to enrich location"
    end
  end
  
  desc "Enrich lodging data for Pebble Beach"
  task :enrich_pebble_beach => :environment do
    puts "Starting lodging enrichment for Pebble Beach..."
    
    location = Location.find_by(name: "Pebble Beach")
    if location.nil?
      puts "Error: Pebble Beach location not found"
      next
    end

    service = LodgingEnrichmentService.new(location)
    result = service.enrich

    if result
      puts "\nLodging Data Summary for #{location.name}:"
      puts "Saved #{result} lodging options"
    else
      puts "Failed to enrich lodging data"
    end
  end

  desc "Estimate lodging prices for all locations"
  task estimate_prices: :environment do
    puts "Starting price estimation for all locations..."
    
    results = []
    Location.find_each do |location|
      estimator = LocationPriceEstimatorService.new(location)
      result = estimator.estimate_prices
      results << result if result
    end
    
    puts "\nPrice estimation complete!"
    puts "Processed #{results.size} locations"
    
    results.each do |result|
      puts "\n#{result[:location]}"
      puts "Lodging Price Range: #{result[:lodging_price_range]}"
      puts "Estimated Trip Cost: $#{result[:estimated_trip_cost]}"
    end
  end
  
  desc "Estimate lodging prices for a specific location"
  task :estimate_location_prices, [:location_id] => :environment do |t, args|
    if args[:location_id].blank?
      puts "Please provide a location ID"
      puts "Usage: rails lodging:estimate_location_prices[123]"
      exit
    end
    
    location = Location.find(args[:location_id])
    estimator = LocationPriceEstimatorService.new(location)
    result = estimator.estimate_prices
    
    if result
      puts "\nPrice estimation complete!"
      puts "Location: #{result[:location]}"
      puts "Lodging Price Range: #{result[:lodging_price_range]}"
      puts "Estimated Trip Cost: $#{result[:estimated_trip_cost]}"
    else
      puts "Failed to estimate prices for location"
    end
  end

  desc "Enrich all locations with lodging data and price estimates"
  task enrich_gold_destinations: :environment do
    puts "Starting enrichment of gold destinations..."
    
    service = EnrichGoldDestinationsService.new
    results = service.enrich_all_locations
    
    puts "\nEnrichment complete!"
    puts "Processed #{results.size} locations"
    
    results.each do |result|
      puts "\n#{result[:location]}"
      puts "Total Lodging Options: #{result[:total_lodging_options]}"
      puts "Lodging Price Range: #{result[:lodging_price_range]}"
      puts "Estimated Trip Cost: $#{result[:estimated_trip_cost]}"
    end
  end

  desc "Test lodging enrichment for a specific location"
  task :test_enrich, [:location_name] => :environment do |t, args|
    if args[:location_name].blank?
      puts "Please provide a location name. Usage: rake lodging:test_enrich[location_name]"
      exit 1
    end

    service = LodgingEnrichmentTestService.new
    result = service.enrich(args[:location_name])
    puts result
  end

  desc "List all lodgings for a specific location"
  task :list, [:location_name] => :environment do |t, args|
    if args[:location_name].blank?
      puts "Please provide a location name"
      puts "Usage: rails lodging:list[Pebble Beach]"
      exit
    end
    
    location = Location.find_by(name: args[:location_name])
    if location.nil?
      puts "Error: Location not found"
      exit
    end
    
    lodgings = location.lodgings.order(rating: :desc)
    
    if lodgings.any?
      puts "\nLodgings for #{location.name}:"
      puts "-" * 50
      lodgings.each_with_index do |lodge, index|
        puts "#{index + 1}. #{lodge.name}"
        puts "   Rating: #{lodge.rating} ★"
        puts "   Address: #{lodge.formatted_address}"
        puts "   Price Range: #{lodge.price_range_display}" if lodge.respond_to?(:price_range_display)
        puts "   Website: #{lodge.website}" if lodge.website.present?
        puts "   Phone: #{lodge.formatted_phone_number}" if lodge.formatted_phone_number.present?
        puts "-" * 50
      end
      puts "Total: #{lodgings.count} lodgings"
    else
      puts "No lodgings found for #{location.name}"
      puts "To find lodgings, run: rails lodging:find_and_enrich[\"#{location.name}\"]"
    end
  end
end 