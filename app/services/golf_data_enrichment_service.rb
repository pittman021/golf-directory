class GolfDataEnrichmentService
  def self.enrich_course(course)
    # Get course details from Google Places API
    place_details = get_place_details(course)
    
    # Update course with enriched data
    course.update!(
      description: place_details[:description],
      website_url: place_details[:website],
      green_fee: place_details[:price_level],
      layout_tags: place_details[:tags],
      notes: place_details[:notes]
    )
    
    # Get course reviews
    reviews = get_course_reviews(course)
    create_reviews(course, reviews) if reviews.present?
  end

  private

  def self.get_place_details(course)
    uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
    params = {
      place_id: course.google_place_id,
      fields: 'name,formatted_address,website,price_level,reviews,types',
      key: Rails.application.credentials.google_maps_api_key
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      result = data['result']
      
      {
        description: generate_description(result),
        website: result['website'],
        price_level: calculate_green_fee(result['price_level']),
        tags: extract_tags(result['types']),
        notes: extract_notes(result['reviews'])
      }
    else
      {}
    end
  end

  def self.get_course_reviews(course)
    uri = URI("https://maps.googleapis.com/maps/api/place/details/json")
    params = {
      place_id: course.google_place_id,
      fields: 'reviews',
      key: Rails.application.credentials.google_maps_api_key
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data['result']['reviews']
    else
      []
    end
  end

  def self.create_reviews(course, reviews)
    reviews.each do |review|
      Review.create!(
        course: course,
        rating: review['rating'],
        comment: review['text'],
        author: review['author_name'],
        source: 'google_places'
      )
    end
  end

  def self.generate_description(place_data)
    types = place_data['types'].join(', ')
    address = place_data['formatted_address']
    "A #{types} golf course located at #{address}"
  end

  def self.calculate_green_fee(price_level)
    case price_level
    when 1 then 50
    when 2 then 100
    when 3 then 150
    when 4 then 200
    else 75
    end
  end

  def self.extract_tags(types)
    tags = []
    tags << 'public' if types.include?('golf_course')
    tags << 'resort' if types.include?('lodging')
    tags << 'championship' if types.include?('stadium')
    tags
  end

  def self.extract_notes(reviews)
    return nil unless reviews.present?
    
    positive = reviews.select { |r| r['rating'] >= 4 }
    common_themes = positive.map { |r| r['text'] }
                           .join(' ')
                           .downcase
                           .split(/[^a-z]+/)
                           .group_by(&:itself)
                           .transform_values(&:count)
                           .sort_by { |_, v| -v }
                           .first(5)
                           .map(&:first)
    
    "Commonly praised for: #{common_themes.join(', ')}"
  end
end 