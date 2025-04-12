# lib/tasks/seed_google_images.rake
require 'net/http'
require 'json'
require 'open-uri'

namespace :seed do
  desc "Fetch and attach images for ALL Locations and Courses using Google Place Photos API"
  task google_place_images: :environment do
    api_key = Rails.application.credentials.google_maps[:api_key]
    
    def fetch_and_attach_photo(entity, api_key)
      # First check if image already exists
      if entity.featured_image.attached?
        puts "✓ Image already exists for #{entity.class.name}: #{entity.name}"
        return false
      end

      # Construct search query based on entity type
      search_query = if entity.is_a?(Course)
        location_name = entity.locations.first&.name
        [entity.name, location_name, "golf course"].compact.join(" ")
      else
        "#{entity.name} golf"
      end

      puts "\nSearching for: #{search_query}"
      puts "Location: #{entity.latitude}, #{entity.longitude}"
      
      search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
      search_params = {
        input: search_query,
        inputtype: 'textquery',
        locationbias: "point:#{entity.latitude},#{entity.longitude}",
        fields: 'place_id,photos,formatted_address',
        key: api_key
      }
      search_url.query = URI.encode_www_form(search_params)

      begin
        search_response = Net::HTTP.get_response(search_url)
        search_data = JSON.parse(search_response.body)
        
        puts "Search Response Status: #{search_data['status']}"
        puts "Found Candidates: #{search_data['candidates']&.length || 0}"

        if search_data['status'] == 'OK'
          place_id = search_data.dig('candidates', 0, 'place_id')
          address = search_data.dig('candidates', 0, 'formatted_address')
          puts "Found Place ID: #{place_id}"
          puts "Address: #{address}"
          
          if place_id
            # Get place details to fetch photo reference
            details_url = URI("https://maps.googleapis.com/maps/api/place/details/json")
            details_params = {
              place_id: place_id,
              fields: 'photos',
              key: api_key
            }
            details_url.query = URI.encode_www_form(details_params)
            
            details_response = Net::HTTP.get_response(details_url)
            details_data = JSON.parse(details_response.body)
            
            if photo_ref = details_data.dig('result', 'photos', 0, 'photo_reference')
              puts "Found photo reference: #{photo_ref[0..20]}..."
              
              # Construct photo URL
              photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
              
              # Download and attach the photo
              begin
                image_response = URI.open(photo_url)
                entity.featured_image.attach(
                  io: image_response,
                  filename: "#{entity.name.parameterize}.jpg",
                  content_type: 'image/jpeg'
                )
                puts "✅ Successfully attached image to #{entity.class.name}: #{entity.name}"
                return true
              rescue OpenURI::HTTPError => e
                puts "❌ Failed to download photo for #{entity.class.name}: #{entity.name} - #{e.message}"
              end
            else
              puts "No photos found in place details"
            end
          end
        else
          puts "❌ Place not found for #{entity.class.name}: #{entity.name} - #{search_data['status']}"
        end
      rescue StandardError => e
        puts "❌ Error processing #{entity.class.name}: #{entity.name} - #{e.message}"
        puts e.backtrace.take(5)
      end
      
      false
    end

    # Process all locations
    puts "\n=== Processing All Locations ==="
    locations_total = Location.count
    locations_processed = 0
    locations_with_images = 0
    
    Location.find_each.with_index(1) do |location, index|
      puts "\n[#{index}/#{locations_total}] Processing Location: #{location.name}"
      
      if location.featured_image.attached?
        puts "✓ Image already exists"
        locations_with_images += 1
        next
      end
      
      if fetch_and_attach_photo(location, api_key)
        locations_with_images += 1
        puts "Waiting 2 seconds before next request..."
        sleep 2
      end
      locations_processed += 1
    end

    # Process all courses
    puts "\n=== Processing All Courses ==="
    courses_total = Course.count
    courses_processed = 0
    courses_with_images = 0
    
    Course.find_each.with_index(1) do |course, index|
      puts "\n[#{index}/#{courses_total}] Processing Course: #{course.name}"
      puts "Part of Location: #{course.locations.first&.name}"
      
      if course.featured_image.attached?
        puts "✓ Image already exists"
        courses_with_images += 1
        next
      end
      
      if fetch_and_attach_photo(course, api_key)
        courses_with_images += 1
        puts "Waiting 2 seconds before next request..."
        sleep 2
      end
      courses_processed += 1
    end

    # Print summary
    puts "\n=== Summary ==="
    puts "Locations:"
    puts "- Total: #{locations_total}"
    puts "- Processed: #{locations_processed}"
    puts "- With Images: #{locations_with_images}"
    puts "\nCourses:"
    puts "- Total: #{courses_total}"
    puts "- Processed: #{courses_processed}"
    puts "- With Images: #{courses_with_images}"
    
    puts "\n🎉 Image seeding complete!"
  end

  desc "Test image fetching with specific locations"
  task test_location_images: :environment do
    api_key = Rails.application.credentials.google_maps[:api_key]
    
    def fetch_and_attach_photo(entity, api_key)
      # First check if image already exists
      if entity.featured_image.attached?
        puts "✓ Image already exists for #{entity.class.name}: #{entity.name}"
        return false
      end

      # Search for the place first
      puts "\nSearching for: #{entity.name}"
      puts "Location: #{entity.latitude}, #{entity.longitude}"
      
      search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
      search_params = {
        input: "#{entity.name} golf",  # Added 'golf' to improve search accuracy
        inputtype: 'textquery',
        locationbias: "point:#{entity.latitude},#{entity.longitude}",  # Use location data to improve results
        fields: 'place_id,photos,formatted_address',
        key: api_key
      }
      search_url.query = URI.encode_www_form(search_params)

      begin
        search_response = Net::HTTP.get_response(search_url)
        search_data = JSON.parse(search_response.body)
        
        puts "Search Response Status: #{search_data['status']}"
        puts "Found Candidates: #{search_data['candidates']&.length || 0}"

        if search_data['status'] == 'OK'
          place_id = search_data.dig('candidates', 0, 'place_id')
          address = search_data.dig('candidates', 0, 'formatted_address')
          puts "Found Place ID: #{place_id}"
          puts "Address: #{address}"
          
          if place_id
            # Get place details to fetch photo reference
            details_url = URI("https://maps.googleapis.com/maps/api/place/details/json")
            details_params = {
              place_id: place_id,
              fields: 'photos',
              key: api_key
            }
            details_url.query = URI.encode_www_form(details_params)
            
            details_response = Net::HTTP.get_response(details_url)
            details_data = JSON.parse(details_response.body)
            
            if photo_ref = details_data.dig('result', 'photos', 0, 'photo_reference')
              puts "Found photo reference: #{photo_ref[0..20]}..."
              
              # Construct photo URL
              photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
              
              # Download and attach the photo
              begin
                image_response = URI.open(photo_url)
                entity.featured_image.attach(
                  io: image_response,
                  filename: "#{entity.name.parameterize}.jpg",
                  content_type: 'image/jpeg'
                )
                puts "✅ Successfully attached image to #{entity.class.name}: #{entity.name}"
                return true
              rescue OpenURI::HTTPError => e
                puts "❌ Failed to download photo for #{entity.class.name}: #{entity.name} - #{e.message}"
              end
            else
              puts "No photos found in place details"
            end
          end
        else
          puts "❌ Place not found for #{entity.class.name}: #{entity.name} - #{search_data['status']}"
          puts "Response: #{search_data.inspect}"
        end
      rescue StandardError => e
        puts "❌ Error processing #{entity.class.name}: #{entity.name} - #{e.message}"
        puts e.backtrace.take(5)
      end
      
      false
    end

    # Test with specific locations
    test_locations = [
      'Pebble Beach',
      'Bandon Dunes',
      'Pinehurst'
    ]

    puts "\nTesting with specific locations..."
    Location.where(name: test_locations).find_each do |location|
      puts "\n=== Processing #{location.name} ==="
      
      if fetch_and_attach_photo(location, api_key)
        puts "Waiting 2 seconds before next request..."
        sleep 2
      end
    end

    puts "\n🎉 Test location image seeding complete!"
  end

  desc "Test image fetching with specific courses"
  task test_course_images: :environment do
    api_key = Rails.application.credentials.google_maps[:api_key]
    
    # Reuse the same fetch_and_attach_photo method from above
    
    # Test with specific courses
    test_courses = [
      'Pebble Beach Golf Links',
      'Pacific Dunes',
      'Pinehurst No. 2'
    ]

    puts "\nTesting with specific courses..."
    Course.where(name: test_courses).find_each do |course|
      puts "\n=== Processing #{course.name} ==="
      puts "Part of Location: #{course.locations.first&.name}"
      
      if course.featured_image.attached?
        puts "✓ Image already exists for Course: #{course.name}"
        next
      end
      
      # Construct a more specific search query using the course name and location
      location_name = course.locations.first&.name
      search_query = [course.name, location_name, "golf course"].compact.join(" ")
      
      search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
      search_params = {
        input: search_query,
        inputtype: 'textquery',
        locationbias: "point:#{course.latitude},#{course.longitude}",
        fields: 'place_id,photos,formatted_address',
        key: api_key
      }
      search_url.query = URI.encode_www_form(search_params)

      begin
        search_response = Net::HTTP.get_response(search_url)
        search_data = JSON.parse(search_response.body)
        
        puts "Search Response Status: #{search_data['status']}"
        puts "Found Candidates: #{search_data['candidates']&.length || 0}"

        if search_data['status'] == 'OK'
          place_id = search_data.dig('candidates', 0, 'place_id')
          address = search_data.dig('candidates', 0, 'formatted_address')
          puts "Found Place ID: #{place_id}"
          puts "Address: #{address}"
          
          if place_id
            # Get place details to fetch photo reference
            details_url = URI("https://maps.googleapis.com/maps/api/place/details/json")
            details_params = {
              place_id: place_id,
              fields: 'photos',
              key: api_key
            }
            details_url.query = URI.encode_www_form(details_params)
            
            details_response = Net::HTTP.get_response(details_url)
            details_data = JSON.parse(details_response.body)
            
            if photo_ref = details_data.dig('result', 'photos', 0, 'photo_reference')
              puts "Found photo reference: #{photo_ref[0..20]}..."
              
              # Construct photo URL
              photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
              
              # Download and attach the photo
              begin
                image_response = URI.open(photo_url)
                course.featured_image.attach(
                  io: image_response,
                  filename: "#{course.name.parameterize}.jpg",
                  content_type: 'image/jpeg'
                )
                puts "✅ Successfully attached image to Course: #{course.name}"
              rescue OpenURI::HTTPError => e
                puts "❌ Failed to download photo for Course: #{course.name} - #{e.message}"
              end
            else
              puts "No photos found in place details"
            end
          end
        else
          puts "❌ Place not found for Course: #{course.name} - #{search_data['status']}"
          puts "Response: #{search_data.inspect}"
        end
      rescue StandardError => e
        puts "❌ Error processing Course: #{course.name} - #{e.message}"
        puts e.backtrace.take(5)
      end

      puts "Waiting 2 seconds before next request..."
      sleep 2
    end

    puts "\n🎉 Test course image seeding complete!"
  end
end
  