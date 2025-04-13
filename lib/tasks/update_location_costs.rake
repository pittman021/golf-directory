# lib/tasks/update_location_costs.rake
namespace :locations do
    desc "Update location costs and fees"
    task update_costs: :environment do
      Location.find_each do |location|
        puts "\nProcessing #{location.name}..."
        
        # Calculate average green fee from associated courses
        avg_fee = location.courses.average(:green_fee).to_i
        location.update_column(:avg_green_fee, avg_fee)
        
        # Process each lodging to estimate prices
        if location.lodgings.any?
          puts "Estimating prices for #{location.lodgings.count} lodgings..."
          
          # Get price estimates for all lodgings
          price_estimates = location.lodgings.map do |lodge|
            begin
              estimator = LodgePriceEstimatorService.new(lodge)
              estimate = estimator.estimate_price
              
              # Validate the estimate
              if estimate.is_a?(Hash) && estimate[:min].is_a?(Numeric) && estimate[:max].is_a?(Numeric)
                # Update the lodge's research status
                lodge.complete_price_research(estimate)
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
          else
            puts "  No valid price estimates were obtained for any lodgings"
          end
        else
          puts "No lodgings found for #{location.name}"
        end
        
        # Update estimated trip cost
        location.calculate_estimated_trip_cost
        location.save
        
        puts "Updated #{location.name}:"
        puts "- Average Green Fee: $#{location.avg_green_fee}"
        if location.lodging_price_min && location.lodging_price_max
          puts "- Lodging Price Range: $#{location.lodging_price_min}-$#{location.lodging_price_max}"
        else
          puts "- Lodging Price Range: Not available"
        end
        puts "- Estimated Trip Cost: $#{location.estimated_trip_cost}"
      end
    end

    desc "Update costs and fees for a specific location"
    task :update_location, [:location_name] => :environment do |t, args|
      if args[:location_name].blank?
        puts "Please provide a location name. Usage: rake locations:update_location[location_name]"
        exit 1
      end

      location = Location.find_by(name: args[:location_name])
      if location.nil?
        puts "Error: Location '#{args[:location_name]}' not found"
        exit 1
      end

      puts "\nProcessing #{location.name}..."
      
      # Calculate average green fee from associated courses
      avg_fee = location.courses.average(:green_fee).to_i
      location.update_column(:avg_green_fee, avg_fee)
      
      # Process each lodging to estimate prices
      if location.lodgings.any?
        puts "Found #{location.lodgings.count} lodgings:"
        location.lodgings.each do |lodge|
          puts "- #{lodge.name} (Rating: #{lodge.rating})"
        end
        
        puts "\nEstimating prices..."
        price_estimates = location.lodgings.map do |lodge|
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
        else
          puts "  No valid price estimates were obtained for any lodgings"
        end
      else
        puts "No lodgings found for #{location.name}"
      end
      
      # Update estimated trip cost
      location.calculate_estimated_trip_cost
      location.save
      
      puts "\nUpdated #{location.name}:"
      puts "- Average Green Fee: $#{location.avg_green_fee}"
      if location.lodging_price_min && location.lodging_price_max
        puts "- Lodging Price Range: $#{location.lodging_price_min}-$#{location.lodging_price_max}"
      else
        puts "- Lodging Price Range: Not available"
      end
      puts "- Estimated Trip Cost: $#{location.estimated_trip_cost}"
    end
  end