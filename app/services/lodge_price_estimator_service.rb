class LodgePriceEstimatorService
  def initialize(lodge)
    @lodge = lodge
  end
  
  def estimate_price
    prompt = build_prompt
    response = call_chatgpt(prompt)
    parse_response(response)
  end
  
  private
  
  def build_prompt
    <<~PROMPT
      Based on the following information about a lodging establishment, estimate the typical price range per night in USD.
      Consider the following factors:
      - Location and proximity to golf courses
      - Rating and likely quality
      - Type of establishment (hotel, resort, etc.)
      - Typical prices for similar establishments in the area
      - Seasonal variations
      - Current market conditions

      Establishment Details:
      Name: #{@lodge.name}
      Location: #{@lodge.location.name}, #{@lodge.location.state}
      Rating: #{@lodge.rating}
      Address: #{@lodge.formatted_address}
      Types: #{@lodge.types.join(', ')}

      Please provide a realistic price range in the format "min-max" (e.g., "200-400").
      Consider that this is a golf destination, which may affect pricing.
      Only respond with the price range in the format "min-max".
    PROMPT
  end
  
  def call_chatgpt(prompt)
    client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])
    
    response = client.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )
    
    response.dig("choices", 0, "message", "content").strip
  end
  
  def parse_response(response)
    return nil unless response.is_a?(String)
    
    puts "Raw price response for #{@lodge.name}: #{response}"
    
    # Extract price range using regex (looking for pattern like "100-200")
    if match = response.match(/(\d+)-(\d+)/)
      min_price = match[1].to_i
      max_price = match[2].to_i
      
      # Ensure min is actually less than max
      if min_price > max_price
        min_price, max_price = max_price, min_price
      end
      
      # Return a hash with min and max prices
      { min: min_price, max: max_price }
    else
      puts "  Invalid price estimate format for #{@lodge.name}: #{response.inspect}"
      nil
    end
  end
end 