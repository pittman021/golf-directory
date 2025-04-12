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
      # Get data from ChatGPT
      data = get_chatgpt_data
      
      # Update location with the data
      if update_location(data)
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

    client = OpenAI::Client.new
    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    JSON.parse(response.dig("choices", 0, "message", "content"))
  end

  def update_location(data)
    @location.update!(
      description: data['description'],
      notable_courses: data['notable_courses'],
      best_time_to_visit: data['best_time_to_visit'],
      special_events: data['special_events'],
      golf_culture: data['golf_culture']
    )
  rescue => e
    puts "Error updating location: #{e.message}"
    false
  end
end 