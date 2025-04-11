# This rake task provides focused enrichment for lodging data only.
# It uses LodgingEnrichmentService to:
# - Search for lodging options within 1-mile radius
# - Update lodging prices and availability
# - Process lodging-specific data
#
# Usage:
#   rails lodging:enrich_pebble_beach
#   rails lodging:enrich_bandon_dunes
#   etc.
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
end 