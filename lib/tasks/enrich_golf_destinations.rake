# This rake task provides comprehensive enrichment for golf destinations.
# It uses GolfDestinationEnrichmentService to:
# - Generate detailed summaries using ChatGPT
# - Update lodging information and prices
# - Calculate estimated trip costs
# - Process all aspects of a golf destination
#
# Usage:
#   rails golf:enrich_destinations                    # Processes all locations
#   rails golf:enrich_destinations[first]             # Processes only the first location
#   rails golf:enrich_destinations[location_id:123]   # Processes location with ID 123
#   rails golf:enrich_destinations[name:"Pinehurst"]  # Processes location named "Pinehurst"
#
# This is the primary task for:
# - Initial setup of new locations
# - Complete refresh of destination data
# - Processing multiple locations at once
# - Processing a single specific location
#
# Note: This task includes lodging enrichment, so separate lodging.rake
# is not strictly necessary unless you need lodging-only updates.

namespace :golf do
  desc "Enrich locations with lodging data and price estimates"
  task :enrich_destinations, [:location_identifier] => :environment do |t, args|
    puts "Starting enrichment of golf destinations..."
    
    if args[:location_identifier].present?
      # Process a specific location
      location = find_location(args[:location_identifier])
      
      if location.nil?
        puts "No matching location found for identifier: #{args[:location_identifier]}"
        exit
      end
      
      puts "\nProcessing location: #{location.name}"
      service = GolfDestinationEnrichmentService.new(location)
      if service.enrich
        puts "✓ Successfully enriched #{location.name}"
        puts "  - Lodging Price Range: #{location.lodging_price_range || 'N/A'}"
        puts "  - Estimated Trip Cost: $#{location.estimated_trip_cost || 'N/A'}"
      else
        puts "✗ Failed to enrich #{location.name}"
      end
    else
      # Process all locations
      total_locations = Location.count
      processed = 0
      successful = 0
      failed = 0
      
      Location.find_each do |location|
        begin
          puts "\nProcessing #{location.name} (#{processed + 1}/#{total_locations})..."
          
          service = GolfDestinationEnrichmentService.new(location)
          if service.enrich
            successful += 1
            puts "✓ Successfully enriched #{location.name}"
            puts "  - Lodging Price Range: #{location.lodging_price_range || 'N/A'}"
            puts "  - Estimated Trip Cost: $#{location.estimated_trip_cost || 'N/A'}"
          else
            failed += 1
            puts "✗ Failed to enrich #{location.name}"
          end
        rescue StandardError => e
          failed += 1
          puts "✗ Error processing #{location.name}: #{e.message}"
          puts "  Error type: #{e.class}"
        end
        
        processed += 1
      end
      
      puts "\nEnrichment complete!"
      puts "Processed: #{processed} locations"
      puts "Successful: #{successful} locations"
      puts "Failed: #{failed} locations"
    end
  end

  private

  def find_location(identifier)
    case identifier
    when 'first'
      Location.first
    when /^location_id:(\d+)$/
      Location.find_by(id: $1)
    when /^name:"([^"]+)"$/
      Location.find_by(name: $1)
    else
      # Try to find by name without quotes
      Location.find_by(name: identifier)
    end
  end
end 