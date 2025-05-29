require_relative 'google_places_base_service'

class GooglePlacesEnrichmentService < GooglePlacesBaseService
  def enrich_courses_with_google_data(courses = nil)
    # Default to courses that need enrichment
    courses ||= Course.where(website_url: "Pending Google enrichment")
    
    puts "🔍 ENRICHING COURSES WITH GOOGLE PLACES DATA"
    puts "=" * 50
    puts "📋 Goal: Add website, phone, rating from Google Places"
    puts "📊 Courses to enrich: #{courses.count}"
    puts
    
    enriched_count = 0
    failed_count = 0
    
    courses.each_with_index do |course, index|
      puts "   🏌️ #{index + 1}/#{courses.count}: #{course.name} (#{course.description})"
      
      google_data = search_google_places(course)
      
      if google_data && update_course_with_google_data(course, google_data)
        puts "     ✅ Enriched successfully"
        enriched_count += 1
      else
        puts "     ❌ Failed to enrich"
        failed_count += 1
      end
      
      # Rate limiting - be respectful to Google API
      sleep(1)
    end
    
    puts
    puts "🎯 ENRICHMENT RESULTS:"
    puts "=" * 25
    puts "   Enriched: #{enriched_count} courses"
    puts "   Failed:   #{failed_count} courses"
    puts
    puts "✅ Google Places enrichment complete!"
    
    enriched_count
  end

  private

  def search_google_places(course)
    # Create search query
    query = "#{course.name} golf course #{course.description}"
    
    puts "     🔍 Searching: '#{query}'"
    
    # Use Google Places Text Search API
    uri = URI("https://maps.googleapis.com/maps/api/place/textsearch/json")
    params = {
      query: query,
      key: @api_key,
      fields: "place_id,name,formatted_address,website,formatted_phone_number,rating,user_ratings_total"
    }
    
    uri.query = URI.encode_www_form(params)
    
    begin
      response = Net::HTTP.get_response(uri)
      
      unless response.is_a?(Net::HTTPSuccess)
        puts "     ❌ HTTP Error: #{response.code}"
        return nil
      end
      
      data = JSON.parse(response.body)
      
      unless data["status"] == "OK"
        puts "     ❌ Google API Error: #{data['status']}"
        return nil
      end
      
      results = data["results"] || []
      
      if results.empty?
        puts "     ⚠️ No results found"
        return nil
      end
      
      # Find best match (first result is usually best)
      best_match = results.first
      
      puts "     🎯 Found: #{best_match['name']}"
      
      # Get detailed place information using inherited method
      fetch_place_details(best_match['place_id'])
      
    rescue => e
      puts "     ❌ Error: #{e.message}"
      nil
    end
  end

  def update_course_with_google_data(course, google_data)
    puts "     🔍 DEBUG: Full Google data received:"
    puts "     #{google_data.inspect}"
    puts
    
    # Log name comparison
    our_name = course.name
    google_name = google_data["name"]
    puts "     📝 NAME COMPARISON:"
    puts "     📝 Our name:    '#{our_name}'"
    puts "     📝 Google name: '#{google_name}'"
    puts "     📝 Match?: #{our_name.downcase == google_name.downcase ? 'EXACT' : 'DIFFERENT'}"
    puts
    
    # Log coordinate comparison
    if google_data["geometry"] && google_data["geometry"]["location"]
      our_lat = course.latitude.to_f
      our_lng = course.longitude.to_f
      google_lat = google_data["geometry"]["location"]["lat"]
      google_lng = google_data["geometry"]["location"]["lng"]
      
      puts "     🗺️ COORDINATE COMPARISON:"
      puts "     🗺️ Our CSV coordinates:    #{our_lat}, #{our_lng}"
      puts "     🗺️ Google coordinates:     #{google_lat}, #{google_lng}"
      
      # Calculate distance difference
      lat_diff = (our_lat - google_lat).abs
      lng_diff = (our_lng - google_lng).abs
      distance_miles = Math.sqrt(lat_diff**2 + lng_diff**2) * 69
      
      puts "     🗺️ Distance difference:    #{distance_miles.round(3)} miles"
      
      if distance_miles < 0.1
        puts "     🗺️ Match?: ✅ VERY CLOSE - Coordinates match well!"
      elsif distance_miles < 1
        puts "     🗺️ Match?: ✅ CLOSE - Minor difference"
      elsif distance_miles < 5
        puts "     🗺️ Match?: ⚠️ MODERATE - Some difference"
      else
        puts "     🗺️ Match?: ❌ LARGE - Significant difference"
      end
      puts
    end
    
    updates = {}
    
    # Update course name with Google's official name
    if google_name && !google_name.empty?
      updates[:name] = google_name
      puts "     📝 Updated name: '#{our_name}' → '#{google_name}'"
    end
    
    # Website
    if google_data["website"] && !google_data["website"].empty?
      updates[:website_url] = google_data["website"]
      puts "     📱 Website: #{google_data['website']}"
    else
      updates[:website_url] = "No website found"
    end
    
    # Phone
    if google_data["formatted_phone_number"] && !google_data["formatted_phone_number"].empty?
      updates[:phone] = google_data["formatted_phone_number"]
      puts "     📞 Phone: #{google_data['formatted_phone_number']}"
    else
      updates[:phone] = "No phone found"
    end
    
    # Google Rating - Use Google's value directly
    if google_data["rating"]
      updates[:google_rating] = google_data["rating"]
      puts "     ⭐ Rating: #{google_data['rating']}"
    end
    
    # Google Reviews Count
    if google_data["user_ratings_total"]
      updates[:google_reviews_count] = google_data["user_ratings_total"]
      puts "     👥 Reviews: #{google_data['user_ratings_total']} total"
    end
    
    # Formatted Address and State Extraction
    if google_data["formatted_address"] && !google_data["formatted_address"].empty?
      updates[:formatted_address] = google_data["formatted_address"]
      puts "     📍 Address: #{google_data['formatted_address']}"
      
      # Extract state using inherited method
      state_match = google_data["formatted_address"].match(/, ([A-Z]{2}) \d{5}/)
      if state_match
        state_abbrev = state_match[1]
        state_name = state_name_from_abbrev(state_abbrev)
        state = find_state_record_by_name(state_name)
        if state
          updates[:state_id] = state.id
          puts "     🏛️ State: #{state.name} (ID: #{state.id})"
        end
      end
    end
    
    # Opening Hours
    if google_data["opening_hours"] && google_data["opening_hours"]["weekday_text"]
      updates[:opening_hours_text] = google_data["opening_hours"]["weekday_text"].join("\n")
      puts "     🕒 Hours: Available"
    end
    
    # Photos - Upload to Cloudinary instead of saving Google Photos URL
    if google_data["photos"] && google_data["photos"].any?
      photo_reference = google_data["photos"].first["photo_reference"]
      if photo_reference
        puts "     📸 Uploading photo to Cloudinary..."
        cloudinary_url = upload_google_photo_to_cloudinary(photo_reference, course.name)
        if cloudinary_url
          updates[:image_url] = cloudinary_url
          puts "     📸 Photo uploaded: #{cloudinary_url}"
        else
          puts "     ⚠️ Photo upload failed, skipping"
        end
        puts "     📸 Available photos: #{google_data['photos'].length} total"
      end
    end
    
    # Let's see what other useful fields come back
    puts "     🏷️ Available fields: #{google_data.keys.join(', ')}"
    
    # Google Place ID for future reference
    if google_data["place_id"]
      updates[:google_place_id] = google_data["place_id"]
      puts "     🆔 Place ID: #{google_data['place_id']}"
    end
    
    # Update notes using inherited method
    updates[:notes] = generate_google_notes(google_data)
    
    # Update course tags
    current_tags = course.course_tags || []
    updates[:course_tags] = (current_tags + ["google-enriched"]).uniq
    
    begin
      puts "     🔍 DEBUG: Updates hash before save:"
      puts "     #{updates.inspect}"
      puts
      course.update!(updates)
      true
    rescue => e
      puts "     ❌ Update error: #{e.message}"
      false
    end
  end

  def upload_google_photo_to_cloudinary(photo_reference, course_name)
    return nil unless photo_reference
    
    begin
      # Build Google Photos API URL
      google_photo_url = build_photo_url(photo_reference, 800)
      
      # Upload to Cloudinary with course name as public_id
      safe_course_name = course_name.downcase.gsub(/[^a-z0-9\s]/, '').gsub(/\s+/, '_')
      cloudinary_options = {
        folder: 'golf_courses',
        public_id: "#{safe_course_name}_#{Time.current.to_i}",
        overwrite: true,
        resource_type: 'image'
      }
      
      cloudinary_url = CloudinaryService.upload(google_photo_url, cloudinary_options)
      
      return cloudinary_url
    rescue => e
      puts "     ❌ Cloudinary upload error: #{e.message}"
      nil
    end
  end
end 