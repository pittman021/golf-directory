# lib/tasks/seed_google_images.rake
require 'net/http'
require 'json'
require 'open-uri'
require 'cloudinary'

namespace :seed do
  desc "Fetch and attach images for ALL Locations and Courses using Google Place Photos API. For Courses, prioritizes populating image_url if nil, then attaches to featured_image."
  task google_place_images: :environment do
    api_key = Rails.application.credentials.google_maps[:api_key]
    
    def fetch_and_attach_photo(entity, api_key)
      # First check if image already exists
      if entity.respond_to?(:featured_image) && entity.featured_image.attached? # Ensure entity responds to featured_image
        puts "✓ Featured image already exists for #{entity.class.name}: #{entity.name}"
        return false # Indicates no new image was attached by this call
      end

      # Construct search query based on entity type
      search_query = if entity.is_a?(Course)
        location_name = entity.locations.first&.name
        [entity.name, location_name, "golf course"].compact.join(" ")
      else # Location
        "#{entity.name} golf"
      end

      puts "\nSearching for: #{search_query}"
      # Ensure latitude and longitude are present, otherwise skip locationbias
      location_bias_query = ""
      if entity.latitude.present? && entity.longitude.present?
        puts "Location: #{entity.latitude}, #{entity.longitude}"
        location_bias_query = "point:#{entity.latitude},#{entity.longitude}"
      else
        puts "Warning: Latitude or Longitude missing for #{entity.name}, proceeding without locationbias."
      end
      
      search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
      search_params = {
        input: search_query,
        inputtype: 'textquery',
        fields: 'place_id,photos,formatted_address',
        key: api_key
      }
      search_params[:locationbias] = location_bias_query if location_bias_query.present?
      search_url.query = URI.encode_www_form(search_params)

      begin
        search_response = Net::HTTP.get_response(search_url)
        search_data = JSON.parse(search_response.body)
        
        puts "Search Response Status: #{search_data['status']}"
        # puts "Found Candidates: #{search_data['candidates']&.length || 0}" # Often too verbose

        if search_data['status'] == 'OK' && search_data['candidates'].present?
          place_id = search_data.dig('candidates', 0, 'place_id')
          # address = search_data.dig('candidates', 0, 'formatted_address') # Not used directly for attachment
          # puts "Found Place ID: #{place_id}"
          # puts "Address: #{address}"
          
          if place_id
            # Get place details to fetch photo reference
            details_url = URI("https://maps.googleapis.com/maps/api/place/details/json")
            details_params = {
              place_id: place_id,
              fields: 'photos', # Only fetch photos field
              key: api_key
            }
            details_url.query = URI.encode_www_form(details_params)
            
            details_response = Net::HTTP.get_response(details_url)
            details_data = JSON.parse(details_response.body)
            
            if photo_ref = details_data.dig('result', 'photos', 0, 'photo_reference')
              # puts "Found photo reference: #{photo_ref[0..20]}..."
              
              # Construct photo URL
              photo_api_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
              
              # Download and attach the photo
              begin
                image_response = URI.open(photo_api_url)
                entity.featured_image.attach(
                  io: image_response,
                  filename: "#{entity.name.parameterize}_google.jpg",
                  content_type: 'image/jpeg'
                )
                if entity.featured_image.attached?
                  puts "✅ Successfully attached featured_image to #{entity.class.name}: #{entity.name}"
                  return true # Indicates a new image was attached
                else
                  puts "❌ Attachment to featured_image failed silently for #{entity.class.name}: #{entity.name}"
                end
              rescue OpenURI::HTTPError => e
                puts "❌ Failed to download photo for #{entity.class.name}: #{entity.name} from #{photo_api_url} - #{e.message}"
              rescue StandardError => e # Catch other potential errors during attach
                puts "❌ Error during featured_image attach for #{entity.class.name}: #{entity.name} - #{e.message}"
              end
            else
              puts "ℹ️ No photos found in place details for #{entity.name} (Place ID: #{place_id})"
            end
          else
            puts "ℹ️ No Place ID found from search for #{entity.name}"
          end
        else
          status_message = search_data['status']
          error_message = search_data['error_message']
          log_message = "❌ Place search failed for #{entity.class.name}: #{entity.name} - Status: #{status_message}"
          log_message += " Error: #{error_message}" if error_message.present?
          puts log_message
        end
      rescue JSON::ParserError => e
        puts "❌ Error parsing JSON response for #{entity.class.name}: #{entity.name} - #{e.message}"
      rescue StandardError => e
        puts "❌ Error processing #{entity.class.name}: #{entity.name} - #{e.message}"
        # puts e.backtrace.take(5) # Usually too verbose for a rake task output
      end
      
      false # Default return if no image was attached
    end

    # New helper method to get Google Photo API URL
    def get_google_photo_api_url(entity, api_key)
      search_query = if entity.is_a?(Course)
        location_name = entity.locations.first&.name # Assuming a course belongs to at least one location
        [entity.name, location_name, "golf course"].compact.join(" ")
      else # Should not be called for Location with this helper in the current plan
        "#{entity.name} golf" 
      end

      puts "\nSearching Google Places for photo API URL for: \"#{search_query}\""
      location_bias_query = ""
      if entity.latitude.present? && entity.longitude.present?
        # puts "Using location bias: #{entity.latitude}, #{entity.longitude}"
        location_bias_query = "point:#{entity.latitude},#{entity.longitude}"
      else
        puts "Warning: Latitude or Longitude missing for #{entity.name}, proceeding without locationbias for URL fetching."
      end
      
      search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
      search_params = {
        input: search_query,
        inputtype: 'textquery',
        fields: 'place_id', # Only need place_id for this step
        key: api_key
      }
      search_params[:locationbias] = location_bias_query if location_bias_query.present?
      search_url.query = URI.encode_www_form(search_params)

      begin
        search_response = Net::HTTP.get_response(search_url)
        search_data = JSON.parse(search_response.body)
        
        # puts "Search for URL - Status: #{search_data['status']}"

        if search_data['status'] == 'OK' && search_data['candidates'].present?
          place_id = search_data.dig('candidates', 0, 'place_id')
          if place_id
            # puts "Found Place ID for URL: #{place_id}"
            details_url = URI("https://maps.googleapis.com/maps/api/place/details/json")
            details_params = {
              place_id: place_id,
              fields: 'photos', # Only need photos field
              key: api_key
            }
            details_url.query = URI.encode_www_form(details_params)
            
            details_response = Net::HTTP.get_response(details_url)
            details_data = JSON.parse(details_response.body)
            
            if photo_ref = details_data.dig('result', 'photos', 0, 'photo_reference')
              # puts "Found photo reference for URL: #{photo_ref[0..20]}..."
              photo_api_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
              puts "Constructed Google Photo API URL: #{photo_api_url}"
              return photo_api_url
            else
              puts "ℹ️ No photo reference found in place details for URL for #{entity.name}"
              return nil
            end
          else
            puts "ℹ️ No Place ID found from search for URL for #{entity.name}"
            return nil
          end
        else
          status_message = search_data['status']
          error_message = search_data['error_message']
          log_message = "❌ Place search for URL failed for #{entity.class.name}: #{entity.name} - Status: #{status_message}"
          log_message += " Error: #{error_message}" if error_message.present?
          puts log_message
          return nil
        end
      rescue JSON::ParserError => e
        puts "❌ Error parsing JSON for URL for #{entity.class.name}: #{entity.name} - #{e.message}"
      rescue StandardError => e
        puts "❌ Error fetching Google Photo API URL for #{entity.class.name}: #{entity.name} - #{e.message}"
      end
      nil # Default return
    end

    # Process all locations
    puts "\n=== Processing All Locations for featured_image ==="
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
    # Modified section for courses with nil image_url
    puts "\n=== Processing Courses with nil image_url ==="
    courses_needing_image_url = Course.where(image_url: nil)
    total_courses_to_check = courses_needing_image_url.count
    courses_image_url_updated = 0
    courses_featured_image_attached_this_run = 0 # For featured_images attached in this specific course loop
    
    # --- Testing Limit --- 
    limit_for_testing = 5 # Set to nil or a large number to process all
    courses_processed_in_this_run = 0
    # --- End Testing Limit ---

    if limit_for_testing
      puts "#{total_courses_to_check} courses found with nil image_url. Processing up to #{limit_for_testing} courses for testing."
    else
      puts "#{total_courses_to_check} courses found with nil image_url. Processing all."
    end

    courses_needing_image_url.find_each.with_index(1) do |course, index|
      # --- Apply Testing Limit --- 
      if limit_for_testing && courses_processed_in_this_run >= limit_for_testing
        puts "\nReached testing limit of #{limit_for_testing} courses. Stopping course processing."
        break
      end
      courses_processed_in_this_run += 1
      # --- End Apply Testing Limit ---

      puts "\n[#{index}/#{total_courses_to_check} (Attempting #{courses_processed_in_this_run}/#{limit_for_testing || 'all'})] Processing Course for image_url: #{course.name} (ID: #{course.id})"
      # puts "Part of Location: #{course.locations.first&.name}" # Good context, can be re-enabled if needed

      google_photo_api_url = get_google_photo_api_url(course, api_key)

      if google_photo_api_url
        # Attempt to update image_url
        begin
          if course.update(image_url: google_photo_api_url)
            puts "✅ Successfully updated image_url for Course: #{course.name}"
            courses_image_url_updated += 1
          else
            puts "❌ Failed to update image_url for Course: #{course.name} - #{course.errors.full_messages.join(', ')}"
          end
        rescue StandardError => e
          puts "❌ Error updating image_url for Course: #{course.name} - #{e.message}"
        end

        # Attempt to attach to featured_image if not already attached, using the fetched URL
        if !course.featured_image.attached?
          puts "Attempting to attach featured_image from the obtained Google URL..."
          begin
            image_response = URI.open(google_photo_api_url) # Use the URL we just got
            course.featured_image.attach(
              io: image_response,
              filename: "#{course.name.parameterize}_google.jpg", # Indicate source
              content_type: 'image/jpeg'
            )
            if course.featured_image.attached? # Verify attachment
              puts "✅ Successfully attached featured_image to Course: #{course.name} using fetched URL."
              courses_featured_image_attached_this_run += 1
            else
              # This case should ideally not happen if attach didn't raise error but didn't attach.
              puts "❌ Attachment to featured_image failed silently for Course: #{course.name}"
            end
          rescue OpenURI::HTTPError => e
            puts "❌ Failed to download photo (from #{google_photo_api_url}) for featured_image on Course: #{course.name} - #{e.message}"
          rescue StandardError => e # Catch other potential errors during attach
            puts "❌ Error attaching featured_image to Course: #{course.name} - #{e.message}"
          end
        else
          puts "✓ Featured image already exists for Course: #{course.name} (image_url may have been updated)."
        end
      else
        puts "ℹ️ No Google Place Photo API URL found to populate image_url for Course: #{course.name}"
      end
      
      puts "Waiting 2 seconds before next API-affecting request..." # Clarify sleep reason
      sleep 2 
    end
    
    # Original course processing loop (commented out as we are replacing its function with the above)
    # puts "\n=== Processing All Courses (Original Logic - Now Deprecated by image_url check) ==="
    # courses_total = Course.count
    # courses_processed = 0 # This was total courses iterated in original task
    # courses_with_images = 0 # This was total courses that ended up with a featured_image
    
    # Course.find_each.with_index(1) do |course, index|
    #   puts "\n[#{index}/#{courses_total}] Processing Course: #{course.name}"
    #   # puts "Part of Location: #{course.locations.first&.name}"
      
    #   # The original task directly called fetch_and_attach_photo for all courses
    #   # to ensure featured_image was present.
    #   # Our new logic above handles courses where image_url is nil, and also attempts
    #   # to set featured_image for them.
    #   # If there's a need to process *all* courses for *featured_image* regardless of image_url state,
    #   # that would require another loop or a modification of the condition.
    #   # For now, the primary goal was to fix nil image_urls.

    #   # if course.featured_image.attached? # This check is inside fetch_and_attach_photo
    #   #   puts "✓ Image already exists"
    #   #   courses_with_images += 1
    #   #   next
    #   # end
      
    #   # if fetch_and_attach_photo(course, api_key)
    #   #   courses_with_images += 1
    #   #   puts "Waiting 2 seconds before next request..."
    #   #   sleep 2
    #   # end
    #   # courses_processed += 1
    # end

    # Print summary
    puts "\n=== Summary ==="
    puts "Locations (featured_image processing):" # Clarify what was processed for locations
    puts "- Total: #{locations_total}"
    puts "- Processed in this run: #{locations_processed}" # Locations attempted for featured_image
    puts "- Now with Featured Images (cumulative): #{Location.joins(:featured_image_attachment).count}" # More accurate count

    puts "\nCourses (image_url and featured_image processing for those with nil image_url):"
    puts "- Courses found with nil image_url: #{total_courses_to_check}"
    if limit_for_testing
      puts "- Courses processed in this run (due to test limit): #{courses_processed_in_this_run -1}" # -1 because we break after incrementing
    end
    puts "- image_url successfully updated: #{courses_image_url_updated}"
    puts "- featured_image newly attached (for these courses): #{courses_featured_image_attached_this_run}"
    
    # Consider if we need stats for courses that *already* had image_url, or overall featured_image count for all courses.
    # For now, the summary focuses on the actions taken by the modified course loop.
    total_courses_with_featured_image = Course.joins(:featured_image_attachment).count
    puts "- Total courses now with a featured_image (cumulative): #{total_courses_with_featured_image}"


    puts "\n🎉 Image seeding and URL population task complete!"
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

  desc "Fetch images only for courses with null image_url"
  task course_images_null_only: :environment do
    puts "Starting to fetch images for courses with null image_url..."
    
    # Get all courses with null image_url
    courses_without_images = Course.where(image_url: nil)
    total_courses = courses_without_images.count
    
    puts "Found #{total_courses} courses without images"
    
    # Process each course
    courses_without_images.find_each.with_index(1) do |course, index|
      puts "\nProcessing course #{index}/#{total_courses}: #{course.name}"
      
      begin
        # Fetch and update the course image using the class method
        if CourseEnrichmentService.fetch_and_update_course_image(course)
          puts "✅ Successfully updated image for course: #{course.name}"
        else
          puts "❌ Failed to update image for course: #{course.name}"
        end
        
        # Add a small delay to avoid hitting API rate limits
        sleep(0.5)
      rescue => e
        puts "Error processing course #{course.name}: #{e.message}"
        next
      end
    end
    
    puts "\nCompleted processing courses without images"
  end

  desc "Find and process missing photos for courses and lodgings using Google Places API"
  task find_missing_photos: :environment do
    api_key = Rails.application.credentials.google_maps[:api_key]
    
    def get_place_id(entity, api_key)
      search_query = if entity.is_a?(Course)
        location_name = entity.locations.first&.name
        [entity.name, location_name, "golf course"].compact.join(" ")
      else # Lodging
        "#{entity.name} lodging"
      end

      location_bias_query = ""
      if entity.latitude.present? && entity.longitude.present?
        location_bias_query = "point:#{entity.latitude},#{entity.longitude}"
      end

      search_url = URI("https://maps.googleapis.com/maps/api/place/findplacefromtext/json")
      search_params = {
        input: search_query,
        inputtype: 'textquery',
        fields: 'place_id',
        key: api_key
      }
      search_params[:locationbias] = location_bias_query if location_bias_query.present?
      search_url.query = URI.encode_www_form(search_params)

      begin
        search_response = Net::HTTP.get_response(search_url)
        search_data = JSON.parse(search_response.body)
        
        if search_data['status'] == 'OK' && search_data['candidates'].present?
          return search_data.dig('candidates', 0, 'place_id')
        end
      rescue StandardError => e
        puts "❌ Error getting place_id for #{entity.class.name}: #{entity.name} - #{e.message}"
      end
      nil
    end

    def get_photo_reference(place_id, api_key)
      return nil unless place_id

      details_url = URI("https://maps.googleapis.com/maps/api/place/details/json")
      details_params = {
        place_id: place_id,
        fields: 'photos',
        key: api_key
      }
      details_url.query = URI.encode_www_form(details_params)
      
      begin
        details_response = Net::HTTP.get_response(details_url)
        details_data = JSON.parse(details_response.body)
        return details_data.dig('result', 'photos', 0, 'photo_reference')
      rescue StandardError => e
        puts "❌ Error getting photo reference for place_id: #{place_id} - #{e.message}"
      end
      nil
    end

    def process_course_photo(course, photo_ref, api_key)
      return false unless photo_ref

      # Get the Google Places photo URL
      photo_api_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=1600&photoreference=#{photo_ref}&key=#{api_key}"
      
      begin
        # Download the image
        image_response = URI.open(photo_api_url)
        
        # Upload to Cloudinary
        upload = Cloudinary::Uploader.upload(
          image_response,
          folder: "golf_directory/courses",
          public_id: "course_#{course.id}_#{SecureRandom.hex(4)}",
          resource_type: "auto"
        )
        
        # Update the course with Cloudinary URL
        if course.update(image_url: upload['secure_url'])
          puts "✅ Successfully updated image_url for Course: #{course.name}"
          return true
        else
          puts "❌ Failed to update image_url for Course: #{course.name} - #{course.errors.full_messages.join(', ')}"
          return false
        end
      rescue StandardError => e
        puts "❌ Error processing photo for Course: #{course.name} - #{e.message}"
        return false
      end
    end

    def process_lodging_photo(lodging, photo_ref, api_key)
      return false unless photo_ref

      # First update the photo_reference
      if lodging.update(photo_reference: photo_ref)
        puts "✅ Updated photo_reference for Lodging: #{lodging.name}"
        
        # Then try to download and attach the photo
        begin
          lodging.download_photo
          if lodging.photo.attached?
            puts "✅ Successfully downloaded and attached photo for Lodging: #{lodging.name}"
            return true
          else
            puts "❌ Photo download failed for Lodging: #{lodging.name}"
            return false
          end
        rescue StandardError => e
          puts "❌ Error downloading photo for Lodging: #{lodging.name} - #{e.message}"
          return false
        end
      else
        puts "❌ Failed to update photo_reference for Lodging: #{lodging.name} - #{lodging.errors.full_messages.join(', ')}"
        return false
      end
    end

    # Find entities missing photos
    courses_without_photos = Course.where(image_url: nil)
    lodgings_without_photos = Lodging.where(photo_reference: nil).or(Lodging.where.missing(:photo_attachment))

    total_entities = courses_without_photos.count + lodgings_without_photos.count
    puts "\nFound #{courses_without_photos.count} courses and #{lodgings_without_photos.count} lodgings without photos"

    # Process courses
    puts "\n=== Processing Courses ==="
    courses_without_photos.find_each.with_index(1) do |course, index|
      puts "\n[#{index}/#{courses_without_photos.count}] Processing Course: #{course.name}"
      
      place_id = get_place_id(course, api_key)
      next unless place_id

      photo_ref = get_photo_reference(place_id, api_key)
      next unless photo_ref

      if process_course_photo(course, photo_ref, api_key)
        puts "✅ Successfully processed photo for Course: #{course.name}"
      end

      # Respect API rate limits
      sleep 2
    end

    # Process lodgings
    puts "\n=== Processing Lodgings ==="
    lodgings_without_photos.find_each.with_index(1) do |lodging, index|
      puts "\n[#{index}/#{lodgings_without_photos.count}] Processing Lodging: #{lodging.name}"
      
      place_id = get_place_id(lodging, api_key)
      next unless place_id

      photo_ref = get_photo_reference(place_id, api_key)
      next unless photo_ref

      if process_lodging_photo(lodging, photo_ref, api_key)
        puts "✅ Successfully processed photo for Lodging: #{lodging.name}"
      end

      # Respect API rate limits
      sleep 2
    end

    puts "\n=== Summary ==="
    puts "Total entities processed: #{total_entities}"
    puts "Courses remaining without photos: #{Course.where(image_url: nil).count}"
    puts "Lodgings remaining without photos: #{Lodging.where(photo_reference: nil).or(Lodging.where.missing(:photo_attachment)).count}"
  end
end
  