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

  desc "Attach images to locations and courses from directories"
  task attach: :environment do
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

    # Process Courses
    puts "\nProcessing Courses..."
    Course.find_each do |course|
      slug = course.name.parameterize
      
      # Look for images with different extensions
      image_file = Dir.glob("#{courses_image_path}/#{slug}.{jpg,jpeg,png,gif}").first
      
      if image_file
        puts "Found image for #{course.name}: #{File.basename(image_file)}"
        begin
          course.featured_image.attach(
            io: File.open(image_file),
            filename: File.basename(image_file),
            content_type: Marcel::MimeType.for(File.open(image_file))
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
end 