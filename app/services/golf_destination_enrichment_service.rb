# This service handles comprehensive enrichment of golf destinations.
# It manages destination-level data including:
# - Destination overviews and summaries
# - Golf experience descriptions
# - Travel information and tips
# - Local attractions and activities
# - Practical travel advice
# - Lodging information and prices
#
# Usage:
#   service = GolfDestinationEnrichmentService.new(location)
#   service.enrich
#
# This service integrates with:
# - CoursesEnrichmentService for course-specific data
# - LodgingEnrichmentService for accommodation data
# - OpenAI for content generation
#
# Note: This service works at the destination level,
# handling entire locations rather than individual courses.

require 'openai'

class GolfDestinationEnrichmentService
  def initialize(location)
    @location = location
  end

  def enrich
    return false unless @location.present?

    puts "\nEnriching #{@location.name} with ChatGPT data..."
    
    begin
      # Step 1: Get general destination data from ChatGPT
      data = get_chatgpt_data
      
      # Step 2: Get lodging data and price estimates
      lodging_data = enrich_lodging_data
      
      # Step 3: Update location with all data
      if update_location(data, lodging_data)
        puts "✓ Successfully enriched #{@location.name}"
        true
      else
        puts "✗ Failed to update #{@location.name}"
        false
      end
    rescue => e
      puts "Error enriching #{@location.name}: #{e.message}"
      false
    end
  end

  private

  def get_chatgpt_data
    prompt = <<~PROMPT
      Please provide information about #{@location.name} as a golf destination. Include:
      1. A brief description of the golf scene
      2. Notable golf courses in the area
      3. Best time of year to visit for golf
      4. Any special events or tournaments
      5. Local golf culture and atmosphere
      
      Format the response as a JSON object with these keys:
      - description
      - notable_courses
      - best_time_to_visit
      - special_events
      - golf_culture
    PROMPT

    client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])
    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  end

  def enrich_lodging_data
    puts "Finding lodging options..."
    enrichment_service = LodgingEnrichmentService.new(@location)
    lodgings = enrichment_service.enrich
    
    if lodgings.any?
      puts "Found #{lodgings.size} lodging options"
      
      # Get price estimates for each lodging
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
        
        {
          lodging_price_min: min_price,
          lodging_price_max: max_price,
          lodging_price_source: 'ChatGPT Estimate',
          lodging_price_notes: "Based on analysis of #{price_estimates.size} lodging options"
        }
      else
        puts "  No valid price estimates were obtained for any lodgings"
        nil
      end
    else
      puts "No lodgings found for #{@location.name}"
      nil
    end
  end

  def update_location(data, lodging_data)
    # Store the ChatGPT data in the summary field as JSON
    update_params = {
      summary: data.to_json
    }
    
    # Add lodging data if available
    if lodging_data.present?
      update_params.merge!(
        lodging_price_min: lodging_data[:lodging_price_min],
        lodging_price_max: lodging_data[:lodging_price_max],
        lodging_price_source: lodging_data[:lodging_price_source],
        lodging_price_notes: lodging_data[:lodging_price_notes]
      )
    end
    
    @location.update!(update_params)
    
    # Update estimated trip cost if we have lodging data
    @location.calculate_estimated_trip_cost if lodging_data.present?
    @location.save
  rescue => e
    puts "Error updating location: #{e.message}"
    false
  end
end 