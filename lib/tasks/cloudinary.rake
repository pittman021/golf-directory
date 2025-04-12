namespace :cloudinary do
  desc "Configure Active Storage to use Cloudinary in production"
  task setup: :environment do
    require 'cloudinary'

    puts "\n=== Configuring Cloudinary for Active Storage ==="

    # Configure Cloudinary
    Cloudinary.config do |config|
      config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
      config.api_key = ENV['CLOUDINARY_API_KEY']
      config.api_secret = ENV['CLOUDINARY_API_SECRET']
      config.secure = true
    end

    # Create storage.yml configuration
    config_path = Rails.root.join('config', 'storage.yml')
    config_content = <<~YAML
      test:
        service: Disk
        root: <%= Rails.root.join("tmp/storage") %>

      local:
        service: Disk
        root: <%= Rails.root.join("storage") %>

      cloudinary:
        service: Cloudinary
        cloud_name: <%= ENV['CLOUDINARY_CLOUD_NAME'] %>
        api_key: <%= ENV['CLOUDINARY_API_KEY'] %>
        api_secret: <%= ENV['CLOUDINARY_API_SECRET'] %>
        folder: golf_directory
    YAML

    File.write(config_path, config_content)
    puts "✅ Created storage.yml configuration"

    # Update environment configuration
    env_config_path = Rails.root.join('config', 'environments', 'production.rb')
    env_config = File.read(env_config_path)
    if env_config.include?('config.active_storage.service = :local')
      env_config.gsub!('config.active_storage.service = :local', 'config.active_storage.service = :cloudinary')
      File.write(env_config_path, env_config)
      puts "✅ Updated production.rb to use Cloudinary"
    else
      puts "⚠️ Could not find storage configuration in production.rb"
    end

    puts "\n=== Cloudinary Setup Complete ==="
    puts "\nNext steps:"
    puts "1. Make sure your Cloudinary credentials are set in your environment variables"
    puts "2. Run 'rails db:migrate' to ensure Active Storage tables are up to date"
    puts "3. Run 'rails active_storage:install' if you haven't already"
  end

  desc "Migrate existing images to Cloudinary"
  task migrate: :environment do
    require 'cloudinary'

    puts "\n=== Starting Image Migration to Cloudinary ==="

    # Configure Cloudinary
    Cloudinary.config do |config|
      config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
      config.api_key = ENV['CLOUDINARY_API_KEY']
      config.api_secret = ENV['CLOUDINARY_API_SECRET']
      config.secure = true
    end

    # Helper method to migrate a single image
    def migrate_to_cloudinary(attachment, model)
      return unless attachment.attached?

      begin
        # Get the local file path
        file_path = ActiveStorage::Blob.service.path_for(attachment.key)
        
        # Upload to Cloudinary
        result = Cloudinary::Uploader.upload(file_path, 
          folder: "golf_directory/#{model.class.name.downcase.pluralize}",
          public_id: "#{model.name.parameterize}-#{attachment.filename.base}",
          resource_type: "auto"
        )

        puts "✅ Successfully migrated #{model.class.name}: #{model.name} to Cloudinary"
      rescue => e
        puts "❌ Failed to migrate #{model.class.name}: #{model.name} - #{e.message}"
      end
    end

    # Process all locations
    puts "\nProcessing Locations..."
    Location.find_each do |location|
      migrate_to_cloudinary(location.featured_image, location)
    end

    # Process all courses
    puts "\nProcessing Courses..."
    Course.find_each do |course|
      migrate_to_cloudinary(course.featured_image, course)
    end

    puts "\n=== Image Migration Complete ==="
  end

  desc "List all Cloudinary assets"
  task list: :environment do
    require 'cloudinary'

    puts "\n=== Listing Cloudinary Assets ==="

    # Configure Cloudinary
    Cloudinary.config do |config|
      config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
      config.api_key = ENV['CLOUDINARY_API_KEY']
      config.api_secret = ENV['CLOUDINARY_API_SECRET']
      config.secure = true
    end

    begin
      # List all resources in the golf_directory folder
      result = Cloudinary::Api.resources(
        type: 'upload',
        prefix: 'golf_directory',
        max_results: 500
      )

      puts "\nFound #{result['resources'].count} assets:"
      result['resources'].each do |resource|
        puts "- #{resource['public_id']} (#{resource['format']}, #{resource['bytes']} bytes)"
      end
    rescue => e
      puts "❌ Error listing assets: #{e.message}"
    end
  end
end 