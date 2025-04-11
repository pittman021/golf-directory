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
      Only respond with the price range in the format "min-max" (e.g., "200-400").
      
      Name: #{@lodge.name}
      Location: #{@lodge.location.name}
      Rating: #{@lodge.rating}
      Address: #{@lodge.address}
      
      Consider factors like:
      - Location and proximity to golf courses
      - Rating and likely quality
      - Type of establishment (hotel, resort, etc.)
      - Typical prices for similar establishments in the area
      
      Respond only with the price range in the format "min-max".
    PROMPT
  end
  
  def call_chatgpt(prompt)
    # TODO: Implement actual ChatGPT API call
    # For now, return a mock response
    "300-500"
  end
  
  def parse_response(response)
    min_price, max_price = response.split('-').map(&:to_i)
    {
      min: min_price,
      max: max_price,
      source: 'ChatGPT Estimate',
      notes: "Estimated based on establishment details and market analysis"
    }
  end
end 