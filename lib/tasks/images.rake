namespace :images do
  desc "Create necessary image directories"
  task setup: :environment do
    # Configuration
    locations_image_path = Rails.root.join('app', 'assets', 'images', 'locations')
    courses_image_path = Rails.root.join('app', 'assets', 'images', 'courses')

    # Create directories if they don't exist
    FileUtils.mkdir_p(locations_image_path)
    FileUtils.mkdir_p(courses_image_path)

    puts "\n=== Image Directory Setup ==="
    puts "Created directories:"
    puts "- #{locations_image_path}"
    puts "- #{courses_image_path}"
    puts "\nTo add images:"
    puts "1. Add location images to: app/assets/images/locations/"
    puts "   Format: location-name.jpg (e.g., bandon-dunes.jpg)"
    puts "2. Add course images to: app/assets/images/courses/"
    puts "   Format: course-name.jpg (e.g., pacific-dunes.jpg)"
    puts "\nThen run: rake images:attach"
  end

  desc "Attach images to locations and courses from directories via Cloudinary"
  task attach: :environment do
    # Access credentials using Rails.application.credentials
    begin
      cloud_name = Rails.application.credentials.cloudinary[:cloud_name]
      api_key = Rails.application.credentials.cloudinary[:api_key]
      api_secret = Rails.application.credentials.cloudinary[:api_secret]
    rescue => e
      puts "Error accessing Cloudinary credentials: #{e.message}"
      puts "Make sure you have configured Cloudinary credentials in your credentials.yml.enc file."
      exit
    end
    
    # Debug: Print credentials
    puts "\n=== Cloudinary Configuration ==="
    puts "Cloudinary Cloud Name: #{cloud_name}"
    puts "Cloudinary API Key: #{api_key}"
    puts "Cloudinary API Secret: #{api_secret}"
    puts "=== End of Configuration ==="

    # Ensure they are set
    if cloud_name.nil? || api_key.nil? || api_secret.nil?
      puts "Cloudinary configuration is missing. Please check your Rails credentials."
      exit
    end
    
    # Configure Cloudinary - needed for the uploader
    Cloudinary.config do |config|
      config.cloud_name = cloud_name
      config.api_key = api_key
      config.api_secret = api_secret
      config.secure = true
    end

    # Set default URL options for routes
    Rails.application.routes.default_url_options = {
      host: "localhost",
      port: 3000,
      protocol: "http"
    }

    # Configuration
    locations_image_path = Rails.root.join('app', 'assets', 'images', 'locations')
    courses_image_path = Rails.root.join('app', 'assets', 'images', 'courses')

    puts "\n=== Starting Image Attachment Process ==="

    # Process Locations
    puts "\nProcessing Locations..."
    Location.find_each do |location|
      slug = location.name.parameterize
      
      # Look for images with different extensions
      image_file = Dir.glob("#{locations_image_path}/#{slug}.{jpg,jpeg,png,gif}").first
      
      if image_file
        puts "Found image for #{location.name}: #{File.basename(image_file)}"
        begin
          # First upload to Cloudinary directly
          puts "  Uploading to Cloudinary..."
          result = Cloudinary::Uploader.upload(image_file, 
            resource_type: "auto",
            folder: "golf_directory", 
            public_id: "location_#{location.id}_#{slug}"
          )
          puts "  Cloudinary upload success: #{result['secure_url']}"
          
          # Store the Cloudinary URL in image_url
          location.update(image_url: result['secure_url'])
          
          # Now attach to Active Storage (which will also use Cloudinary)
          puts "  Attaching to Active Storage..."
          
          # Remove existing attachment if any
          location.featured_image.purge if location.featured_image.attached?
          
          # Create a temp file from the Cloudinary URL
          require 'open-uri'
          downloaded_image = URI.open(result['secure_url'])
          
          # Attach to Active Storage
          location.featured_image.attach(
            io: downloaded_image,
            filename: File.basename(image_file),
            content_type: result['resource_type'] + '/' + result['format']
          )
          
          puts "✓ Successfully attached image to #{location.name}"
        rescue => e
          puts "✗ Error attaching image to #{location.name}: #{e.message}"
        end
      else
        puts "- No image found for #{location.name} (looking for #{slug}.{jpg,jpeg,png,gif})"
      end
    end

    # Process Courses
    puts "\nProcessing Courses..."
    Course.find_each do |course|
      slug = course.name.parameterize
      
      # Look for images with different extensions
      image_file = Dir.glob("#{courses_image_path}/#{slug}.{jpg,jpeg,png,gif}").first
      
      if image_file
        puts "Found image for #{course.name}: #{File.basename(image_file)}"
        begin
          # First upload to Cloudinary directly
          puts "  Uploading to Cloudinary..."
          result = Cloudinary::Uploader.upload(image_file, 
            resource_type: "auto",
            folder: "golf_directory", 
            public_id: "course_#{course.id}_#{slug}"
          )
          puts "  Cloudinary upload success: #{result['secure_url']}"
          
          # Store the Cloudinary URL in image_url
          course.update(image_url: result['secure_url'])
          
          # Now attach to Active Storage (which will also use Cloudinary)
          puts "  Attaching to Active Storage..."
          
          # Remove existing attachment if any
          course.featured_image.purge if course.featured_image.attached?
          
          # Create a temp file from the Cloudinary URL
          require 'open-uri'
          downloaded_image = URI.open(result['secure_url'])
          
          # Attach to Active Storage
          course.featured_image.attach(
            io: downloaded_image,
            filename: File.basename(image_file),
            content_type: result['resource_type'] + '/' + result['format']
          )
          
          puts "✓ Successfully attached image to #{course.name}"
        rescue => e
          puts "✗ Error attaching image to #{course.name}: #{e.message}"
        end
      else
        puts "- No image found for #{course.name} (looking for #{slug}.{jpg,jpeg,png,gif})"
      end
    end

    puts "\n=== Image Attachment Process Complete ==="
  end

  desc "Attach images to locations only"
  task attach_locations: :environment do
    # Configuration
    locations_image_path = Rails.root.join('app', 'assets', 'images', 'locations')

    # Create directory if it doesn't exist
    FileUtils.mkdir_p(locations_image_path)

    puts "\n=== Starting Location Images Attachment Process ==="

    # Process Locations
    puts "\nProcessing Locations..."
    Location.find_each do |location|
      slug = location.name.parameterize
      
      # Look for images with different extensions
      image_file = Dir.glob("#{locations_image_path}/#{slug}.{jpg,jpeg,png,gif}").first
      
      if image_file
        puts "Found image for #{location.name}: #{File.basename(image_file)}"
        begin
          location.featured_image.attach(
            io: File.open(image_file),
            filename: File.basename(image_file),
            content_type: Marcel::MimeType.for(File.open(image_file))
          )
          puts "✓ Successfully attached image to #{location.name}"
        rescue => e
          puts "✗ Error attaching image to #{location.name}: #{e.message}"
        end
      else
        puts "- No image found for #{location.name} (looking for #{slug}.{jpg,jpeg,png,gif})"
      end
    end

    puts "\n=== Location Images Attachment Process Complete ==="
  end

  desc "List all attached and missing images"
  task status: :environment do
    puts "\n=== Image Status Report ==="
    
    puts "\nLocations:"
    puts "-----------"
    Location.find_each do |location|
      status = location.featured_image.attached? ? "✓" : "✗"
      puts "#{status} #{location.name}"
    end

    puts "\nCourses:"
    puts "--------"
    Course.find_each do |course|
      status = course.featured_image.attached? ? "✓" : "✗"
      puts "#{status} #{course.name}"
    end
  end

  desc "Remove all attached images"
  task remove_all: :environment do
    puts "\n=== Removing All Images ==="
    
    puts "\nRemoving Location Images..."
    Location.find_each do |location|
      if location.featured_image.attached?
        location.featured_image.purge
        puts "✓ Removed image from #{location.name}"
      end
    end

    puts "\nRemoving Course Images..."
    Course.find_each do |course|
      if course.featured_image.attached?
        course.featured_image.purge
        puts "✓ Removed image from #{course.name}"
      end
    end

    puts "\n=== Image Removal Complete ==="
  end

  desc "Attach image to Pebble Beach location only (simple version)"
  task attach_pebble_simple: :environment do
    puts "Starting simple Pebble Beach image attachment task..."
    
    # Set default URL options for routes
    Rails.application.routes.default_url_options = {
      host: "localhost",
      port: 3000,
      protocol: "http"
    }
    
    # Find Pebble Beach location
    location = Location.find_by(name: "Pebble Beach")
    
    if location.nil?
      puts "Error: Pebble Beach location not found in the database."
      exit
    end
    
    # Find the image file
    image_path = Rails.root.join('app', 'assets', 'images', 'locations', 'pebble-beach.jpg')
    
    if !File.exist?(image_path)
      puts "Error: Image file not found at #{image_path}"
      exit
    end
    
    puts "Found image file: #{image_path}"
    
    # Remove any existing attachment
    if location.featured_image.attached?
      puts "Removing existing image attachment..."
      location.featured_image.purge
    end
    
    # Attach the image directly using Active Storage
    puts "Attaching image to location via Active Storage..."
    location.featured_image.attach(
      io: File.open(image_path),
      filename: File.basename(image_path),
      content_type: "image/jpeg"
    )
    
    # Verify attachment
    if location.featured_image.attached?
      puts "✓ Successfully attached image to Pebble Beach"
      
      # Update the image_url field directly as well
      puts "Updating image_url field..."
      
      begin
        # Get the URL from Active Storage
        url = Rails.application.routes.url_helpers.url_for(location.featured_image)
        puts "Active Storage URL: #{url}"
        
        # Also set the image_url field
        location.update(image_url: url)
      rescue => e
        puts "Warning: Could not generate URL: #{e.message}"
        puts "The image is still attached, but the image_url field was not updated."
      end
      
      puts "Task completed successfully."
    else
      puts "❌ Failed to attach image to Pebble Beach"
    end
  end

  desc "Upload existing Active Storage images to Cloudinary"
  task upload_existing: :environment do
    # Access credentials using Rails.application.credentials
    begin
      cloud_name = Rails.application.credentials.cloudinary[:cloud_name]
      api_key = Rails.application.credentials.cloudinary[:api_key]
      api_secret = Rails.application.credentials.cloudinary[:api_secret]
    rescue => e
      puts "Error accessing Cloudinary credentials: #{e.message}"
      puts "Make sure you have configured Cloudinary credentials in your credentials.yml.enc file."
      exit
    end
    
    # Debug: Print credentials
    puts "\n=== Cloudinary Configuration ==="
    puts "Cloudinary Cloud Name: #{cloud_name}"
    puts "Cloudinary API Key: #{api_key}"
    puts "Cloudinary API Secret: #{api_secret}"
    puts "=== End of Configuration ==="

    # Ensure they are set
    if cloud_name.nil? || api_key.nil? || api_secret.nil?
      puts "Cloudinary configuration is missing. Please check your Rails credentials."
      exit
    end
    
    # Configure Cloudinary - needed for the uploader
    Cloudinary.config do |config|
      config.cloud_name = cloud_name
      config.api_key = api_key
      config.api_secret = api_secret
      config.secure = true
    end

    # Set default URL options for routes
    Rails.application.routes.default_url_options = {
      host: "localhost",
      port: 3000,
      protocol: "http"
    }
    
    puts "\n=== Starting Image Upload Process ==="

    # Process Locations with existing attachments
    puts "\nProcessing Locations with existing images..."
    Location.all.each do |location|
      if location.featured_image.attached?
        puts "Processing #{location.name}..."
        
        begin
          # Get the blob
          blob = location.featured_image.blob
          
          # Create a temporary file
          temp_file = Tempfile.new([blob.filename.base, blob.filename.extension_with_delimiter])
          temp_file.binmode
          
          # Download blob to temporary file
          blob.download do |chunk|
            temp_file.write(chunk)
          end
          temp_file.flush
          temp_file.rewind
          
          # Upload to Cloudinary
          puts "  Uploading to Cloudinary..."
          result = Cloudinary::Uploader.upload(temp_file.path, 
            resource_type: "auto",
            folder: "golf_directory", 
            public_id: "location_#{location.id}_#{location.name.parameterize}"
          )
          puts "  Cloudinary upload success: #{result['secure_url']}"
          
          # Store the Cloudinary URL in image_url
          location.update(image_url: result['secure_url'])
          
          puts "✓ Successfully uploaded image for #{location.name}"
          
          # Clean up temp file
          temp_file.close
          temp_file.unlink
        rescue => e
          puts "  ✗ Error processing image for #{location.name}: #{e.message}"
        end
      else
        puts "Skipping #{location.name} - no image attached"
      end
    end

    # Process Courses with existing attachments
    puts "\nProcessing Courses with existing images..."
    Course.all.each do |course|
      if course.featured_image.attached?
        puts "Processing #{course.name}..."
        
        begin
          # Get the blob
          blob = course.featured_image.blob
          
          # Create a temporary file
          temp_file = Tempfile.new([blob.filename.base, blob.filename.extension_with_delimiter])
          temp_file.binmode
          
          # Download blob to temporary file
          blob.download do |chunk|
            temp_file.write(chunk)
          end
          temp_file.flush
          temp_file.rewind
          
          # Upload to Cloudinary
          puts "  Uploading to Cloudinary..."
          result = Cloudinary::Uploader.upload(temp_file.path, 
            resource_type: "auto",
            folder: "golf_directory", 
            public_id: "course_#{course.id}_#{course.name.parameterize}"
          )
          puts "  Cloudinary upload success: #{result['secure_url']}"
          
          # Store the Cloudinary URL in image_url
          course.update(image_url: result['secure_url'])
          
          puts "✓ Successfully uploaded image for #{course.name}"
          
          # Clean up temp file
          temp_file.close
          temp_file.unlink
        rescue => e
          puts "  ✗ Error processing image for #{course.name}: #{e.message}"
        end
      else
        puts "Skipping #{course.name} - no image attached"
      end
    end

    puts "\n=== Image Upload Process Complete ==="
  end

  desc "Export full locations and courses data for production import"
  task export_data: :environment do
    puts "\n=== Exporting Locations and Courses Data ==="
    
    # Create output directory if it doesn't exist
    FileUtils.mkdir_p(Rails.root.join('tmp'))
    sql_file_path = Rails.root.join('tmp', 'locations_courses_export.sql')
    
    File.open(sql_file_path, 'w') do |file|
      file.puts "-- Full export of locations and courses from #{Rails.env} environment"
      file.puts "-- Generated on #{Time.now}"
      file.puts "-- This file contains INSERT statements that will replace existing records in the target database"
      file.puts
      
      # Export Locations
      puts "\nExporting Locations..."
      file.puts "-- LOCATIONS DATA"
      file.puts "-- First, disable triggers to avoid foreign key conflicts"
      file.puts "SET session_replication_role = 'replica';"
      file.puts
      
      count = 0
      Location.find_each do |location|
        # Get all columns from the record
        attributes = location.attributes
        
        # Build column names string
        columns = attributes.keys.map { |k| "\"#{k}\"" }.join(', ')
        
        # Build values string, properly escaping SQL values
        values = attributes.values.map do |v|
          if v.nil?
            "NULL"
          elsif v.is_a?(String)
            "'#{v.gsub("'", "''")}'"
          elsif v.is_a?(Array)
            "ARRAY[#{v.map { |item| "'#{item.gsub("'", "''")}'" }.join(', ')}]"
          elsif v.is_a?(TrueClass) || v.is_a?(FalseClass)
            v ? "TRUE" : "FALSE"
          else
            v.to_s
          end
        end.join(', ')
        
        # Write the INSERT statement with ON CONFLICT DO UPDATE
        file.puts "INSERT INTO locations (#{columns})"
        file.puts "VALUES (#{values})"
        file.puts "ON CONFLICT (id) DO UPDATE SET"
        
        # Create the SET clause for the UPDATE part
        update_sets = attributes.keys.map do |k|
          "\"#{k}\" = EXCLUDED.\"#{k}\""
        end.join(', ')
        
        file.puts "  #{update_sets};"
        file.puts
        
        count += 1
      end
      puts "Exported #{count} locations"
      
      # Export Courses
      puts "\nExporting Courses..."
      file.puts "-- COURSES DATA"
      file.puts
      
      count = 0
      Course.find_each do |course|
        # Get all columns from the record
        attributes = course.attributes
        
        # Build column names string
        columns = attributes.keys.map { |k| "\"#{k}\"" }.join(', ')
        
        # Build values string, properly escaping SQL values
        values = attributes.values.map do |v|
          if v.nil?
            "NULL"
          elsif v.is_a?(String)
            "'#{v.gsub("'", "''")}'"
          elsif v.is_a?(Array)
            "ARRAY[#{v.map { |item| "'#{item.gsub("'", "''")}'" }.join(', ')}]"
          elsif v.is_a?(TrueClass) || v.is_a?(FalseClass)
            v ? "TRUE" : "FALSE"
          else
            v.to_s
          end
        end.join(', ')
        
        # Write the INSERT statement with ON CONFLICT DO UPDATE
        file.puts "INSERT INTO courses (#{columns})"
        file.puts "VALUES (#{values})"
        file.puts "ON CONFLICT (id) DO UPDATE SET"
        
        # Create the SET clause for the UPDATE part
        update_sets = attributes.keys.map do |k|
          "\"#{k}\" = EXCLUDED.\"#{k}\""
        end.join(', ')
        
        file.puts "  #{update_sets};"
        file.puts
        
        count += 1
      end
      puts "Exported #{count} courses"
      
      # Reset session_replication_role
      file.puts "-- Reset triggers"
      file.puts "SET session_replication_role = 'origin';"
    end
    
    puts "\n=== Export Complete ==="
    puts "SQL file saved to: #{sql_file_path}"
    puts 
    puts "To import to production:"
    puts "1. Copy this file to your production server"
    puts "2. Run in production: psql <database_name> < #{File.basename(sql_file_path)}"
    puts "   or within Rails: rails dbconsole production < #{File.basename(sql_file_path)}"
  end

  puts "Cloudinary Cloud Name: \\#{ENV['CLOUDINARY_CLOUD_NAME']}"
  puts "Cloudinary API Key: \\#{ENV['CLOUDINARY_API_KEY']}"
  puts "Cloudinary API Secret: \\#{ENV['CLOUDINARY_API_SECRET']}"
end 