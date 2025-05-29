require 'net/http'
require 'uri'
require 'json'

class GooglePlacesBaseService
  def initialize
    @api_key = if Rails.env.production?
      Rails.application.credentials.google_maps[:api_key]
    else
      Rails.application.credentials.google_maps[:development_api_key]
    end
  end

  protected

  def fetch_place_details(place_id, fields = nil)
    # Default comprehensive fields if none specified - now including geometry
    fields ||= "place_id,name,website,formatted_phone_number,rating,user_ratings_total,formatted_address,opening_hours,photos,price_level,types,editorial_summary,geometry"
    
    uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
    params = {
      place_id: place_id,
      key: @api_key,
      fields: fields
    }
    
    uri.query = URI.encode_www_form(params)
    
    begin
      response = Net::HTTP.get_response(uri)
      
      unless response.is_a?(Net::HTTPSuccess)
        return nil
      end
      
      data = JSON.parse(response.body)
      
      if data["status"] == "OK" && data["result"]
        # Always ensure place_id is included in the result
        result = data["result"]
        result["place_id"] = place_id
        result
      else
        puts "    ⚠️ Place details error: #{data['status']}" if defined?(puts)
        nil
      end
      
    rescue => e
      puts "    ❌ Details error: #{e.message}" if defined?(puts)
      nil
    end
  end

  def extract_state_from_address(address)
    return nil unless address
    
    state_mappings = get_state_mappings
    
    # Split address into parts
    address_parts = address.split(',').map(&:strip)
    
    # Look for state abbreviation (usually second to last part)
    address_parts.each do |part|
      # Check for state abbreviation
      state_abbrev = part.match(/\b([A-Z]{2})\b/)
      if state_abbrev && state_mappings[state_abbrev[1]]
        return state_mappings[state_abbrev[1]]
      end
      
      # Check for full state name
      state_mappings.values.each do |state_name|
        if part.downcase.include?(state_name.downcase)
          return state_name
        end
      end
    end
    
    nil
  end

  def state_name_from_abbrev(abbrev)
    get_state_mappings[abbrev] || abbrev
  end

  def build_photo_url(photo_reference, max_width = 800)
    return nil unless photo_reference
    "https://maps.googleapis.com/maps/api/place/photo?maxwidth=#{max_width}&photo_reference=#{photo_reference}&key=#{@api_key}"
  end

  def process_google_rating(rating)
    return nil unless rating
    rating.to_f.round(1)
  end

  def reverse_geocode(lat, lng)
    uri = URI("https://maps.googleapis.com/maps/api/geocode/json")
    uri.query = URI.encode_www_form(latlng: "#{lat},#{lng}", key: @api_key)
    
    begin
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)
  
      data = JSON.parse(response.body)
      
      # Enhanced state extraction - look through all results for the most accurate match
      data["results"]&.each do |result|
        result["address_components"]&.each do |component|
          if component["types"].include?("administrative_area_level_1")
            return component["long_name"]
          end
        end
      end
      
      nil
    rescue StandardError => e
      puts "    ⚠️ Reverse geocoding failed: #{e.message}" if defined?(puts)
      nil
    end
  end

  def find_state_record_by_name(state_name)
    State.find_by("name ILIKE ?", state_name)
  end

  def generate_google_notes(place_details)
    notes = "More information coming soon!"
  end

  def price_level_description(price_level)
    case price_level
    when 0
      "(Free)"
    when 1
      "(Inexpensive)"
    when 2
      "(Moderate)"
    when 3
      "(Expensive)"
    when 4
      "(Very Expensive)"
    else
      ""
    end
  end

  private

  def get_state_mappings
    {
      'AL' => 'Alabama', 'AK' => 'Alaska', 'AZ' => 'Arizona', 'AR' => 'Arkansas', 'CA' => 'California',
      'CO' => 'Colorado', 'CT' => 'Connecticut', 'DE' => 'Delaware', 'FL' => 'Florida', 'GA' => 'Georgia',
      'HI' => 'Hawaii', 'ID' => 'Idaho', 'IL' => 'Illinois', 'IN' => 'Indiana', 'IA' => 'Iowa',
      'KS' => 'Kansas', 'KY' => 'Kentucky', 'LA' => 'Louisiana', 'ME' => 'Maine', 'MD' => 'Maryland',
      'MA' => 'Massachusetts', 'MI' => 'Michigan', 'MN' => 'Minnesota', 'MS' => 'Mississippi', 'MO' => 'Missouri',
      'MT' => 'Montana', 'NE' => 'Nebraska', 'NV' => 'Nevada', 'NH' => 'New Hampshire', 'NJ' => 'New Jersey',
      'NM' => 'New Mexico', 'NY' => 'New York', 'NC' => 'North Carolina', 'ND' => 'North Dakota', 'OH' => 'Ohio',
      'OK' => 'Oklahoma', 'OR' => 'Oregon', 'PA' => 'Pennsylvania', 'RI' => 'Rhode Island', 'SC' => 'South Carolina',
      'SD' => 'South Dakota', 'TN' => 'Tennessee', 'TX' => 'Texas', 'UT' => 'Utah', 'VT' => 'Vermont',
      'VA' => 'Virginia', 'WA' => 'Washington', 'WV' => 'West Virginia', 'WI' => 'Wisconsin', 'WY' => 'Wyoming'
    }
  end
end 