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
      Please provide comprehensive information about #{@location.name} as a golf destination. 
      Format the response as a detailed JSON object with these exact keys:
      
      - description: A detailed overview of #{@location.name} as a golf destination (2-3 paragraphs)
      - notable_courses: A bullet-point list of 3-5 notable golf courses in the area with brief descriptions
      - best_time_to_visit: Information about weather patterns and optimal seasons for golfing
      - special_events: Any tournaments, golf festivals, or special events held in the area
      - golf_culture: The local golf atmosphere, traditions, and unique aspects of golfing in this area
      - local_attractions: Brief overview of non-golf attractions visitors might enjoy
      - practical_tips: Useful information like transportation options, golf packages, or booking advice
      
      Return only the JSON object without any additional text or explanations.
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
          lodging_price_max: max_price
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
    # Transform the ChatGPT data into the expected format for the Location model
    transformed_data = {
      'destination_overview' => data['description'] || '',
      'golf_experience' => [
        (data['notable_courses'].present? ? "Notable Courses:\n#{data['notable_courses']}" : ''),
        (data['special_events'].present? ? "Events & Tournaments:\n#{data['special_events']}" : ''),
        (data['golf_culture'].present? ? "Golf Culture:\n#{data['golf_culture']}" : '')
      ].reject(&:empty?).join("\n\n"),
      'travel_information' => data['best_time_to_visit'] || '',
      'local_attractions' => data['local_attractions'] || '',
      'practical_tips' => data['practical_tips'] || ''
    }
    
    # Remove any empty fields
    transformed_data.each do |key, value|
      transformed_data[key] = nil if value.blank?
    end
    
    # Store the transformed data in the summary field as JSON
    update_params = {
      summary: transformed_data.to_json
    }
    
    # Add lodging data if available
    if lodging_data.present?
      update_params.merge!(
        lodging_price_min: lodging_data[:lodging_price_min],
        lodging_price_max: lodging_data[:lodging_price_max],
        lodging_price_currency: 'USD',
        lodging_price_last_updated: Time.current
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