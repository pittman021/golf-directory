namespace :images do
  desc "Check and prepare for migration of images"
  task check_models: :environment do
    puts "Checking Location model..."
    if Location.method_defined?(:featured_image)
      puts "  ✓ Location model has :featured_image method"
    else
      puts "  ✗ Location model does not have :featured_image method"
    end

    puts "Checking Course model..."
    if Course.method_defined?(:featured_image)
      puts "  ✓ Course model has :featured_image method"
    else
      puts "  ✗ Course model does not have :featured_image method"
    end
  end

  desc "Migrate ActiveStorage images to direct Cloudinary URLs"
  task migrate_to_cloudinary: :environment do
    begin
      # Process Location images
      puts "Migrating Location images..."
      if Location.method_defined?(:featured_image)
        Location.all.each do |location|
          if location.featured_image.attached?
            begin
              # Get the URL from ActiveStorage
              url = Rails.application.routes.url_helpers.rails_blob_url(location.featured_image, only_path: false, host: 'localhost:3000')
              puts "  Processing #{location.name}: #{url}"
              
              # Get the URL from ActiveStorage using blob.url
              url = location.featured_image.blob.url
              puts "  Processing #{location.name}: #{url}"
              
              # Store it directly in the location
              location.update(image_url: url)
              puts "  ✓ Success: #{location.name}"
            rescue => e
              puts "  ✗ Error processing #{location.name}: #{e.message}"
            end

            begin
              # Get the URL directly from the blob
              url = location.featured_image.blob.url
              puts "  Processing #{location.name}: #{url}"
              
              # Store it directly in the location
              location.update(image_url: url)
              puts "  ✓ Success: #{location.name}"
            rescue => e
              puts "  ✗ Error processing #{location.name}: #{e.message}"
            end
          else
            puts "  ⚠ No image for #{location.name}"
          end
        end
      else
        puts "  ✗ Location model no longer has ActiveStorage attachments"
        puts "    You need to add 'has_one_attached :featured_image' back to the Location model temporarily for migration"
      end

      # Process Course images
      puts "\nMigrating Course images..."
      if Course.method_defined?(:featured_image)
        Course.all.each do |course|
          if course.featured_image.attached?
            begin
              # Get the URL from ActiveStorage
              url = Rails.application.routes.url_helpers.rails_blob_url(course.featured_image, only_path: false, host: 'localhost:3000')
              puts "  Processing #{course.name}: #{url}"
              
              # Store it directly in the course
              course.update(image_url: url)
              puts "  ✓ Success: #{course.name}"
            rescue => e
              puts "  ✗ Error processing #{course.name}: #{e.message}"
            end

            begin
              # Get the URL directly from the blob
              url = course.featured_image.blob.url
              puts "  Processing #{course.name}: #{url}"
              
              # Store it directly in the course
              course.update(image_url: url)
              puts "  ✓ Success: #{course.name}"
            rescue => e
              puts "  ✗ Error processing #{course.name}: #{e.message}"
            end
          else
            puts "  ⚠ No image for #{course.name}"
          end
        end
      else
        puts "  ✗ Course model no longer has ActiveStorage attachments"
        puts "    You need to add 'has_one_attached :featured_image' back to the Course model temporarily for migration"
      end
    rescue => e
      puts "Error during migration: #{e.message}"
    end

    puts "\nMigration check completed!"
  end
end 