namespace :db do
  desc "Export database data (use TYPE=production for production-ready dump)"
  task export: :environment do
    # Check if we have a valid database connection
    begin
      ActiveRecord::Base.connection
    rescue => e
      puts "Error: Unable to connect to database"
      puts "Please ensure your database is properly configured in database.yml or DATABASE_URL is set"
      exit 1
    end

    puts "\n=== Exporting Database Data ==="
    
    # Create output directory if it doesn't exist
    FileUtils.mkdir_p(Rails.root.join('tmp'))
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    dump_type = ENV['TYPE'] == 'production' ? 'dev_to_prod' : 'golf_directory'
    dump_file = Rails.root.join('tmp', "#{dump_type}_#{timestamp}.dump")
    
    # Get database configuration
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    
    # Build pg_dump command
    pg_dump_cmd = [
      "pg_dump",
      "--format=custom", # Use custom format (compressed and flexible)
      "--no-owner",     # Skip commands to set ownership of objects
      "--no-acl",       # Skip access privileges (grant/revoke commands)
      "--clean",        # Include commands to clean (drop) database objects before recreating
      "--if-exists",    # Use IF EXISTS when dropping objects
      "--file=#{dump_file}",
      config[:database]
    ]
    
    # Add host if specified
    pg_dump_cmd.insert(1, "--host=#{config[:host]}") if config[:host]
    
    # Add port if specified
    pg_dump_cmd.insert(1, "--port=#{config[:port]}") if config[:port]
    
    # Add username if specified
    pg_dump_cmd.insert(1, "--username=#{config[:username]}") if config[:username]
    
    # Join command and execute
    cmd = pg_dump_cmd.join(" ")
    puts "Running: #{cmd}"
    
    if system(cmd)
      puts "\n✅ Export Complete"
      puts "Database dump saved to: #{dump_file}"
      
      if ENV['TYPE'] == 'production'
        puts "\n=== Next Step: Upload and Restore to Production ==="
        puts <<~INSTRUCTIONS

          1. Copy the file to your production server:

             scp #{dump_file} your-server:/tmp/

          2. SSH into your production server and run:

             pg_restore --verbose --clean --no-acl --no-owner \\
               --dbname="postgres://[username]:[password]@[host]/[db_name]" \\
               /tmp/#{File.basename(dump_file)}

          Replace the values above with your actual Render credentials.

        INSTRUCTIONS
      else
        puts "\nTo import this dump:"
        puts "pg_restore -d <database_name> #{File.basename(dump_file)}"
        puts "or within Rails: rails dbconsole < #{File.basename(dump_file)}"
      end
    else
      puts "\n❌ Error: Database export failed"
      exit 1
    end
  end

  desc "Analyze courses that need enrichment"
  task analyze_courses: :environment do
    puts "\n=== Analyzing Courses That Need Enrichment ==="
    
    # Find courses with minimal information
    minimal_courses = Course.where("description IS NULL OR description = ''")
    puts "\nCourses with no description: #{minimal_courses.count}"
    minimal_courses.each do |course|
      puts "- #{course.name} (#{course.locations.first&.name})"
    end

    # Find courses with default Google Places import note
    google_imported = Course.where("notes LIKE '%Automatically imported from Google Places API%'")
    puts "\nCourses imported from Google Places (needs enrichment): #{google_imported.count}"
    google_imported.each do |course|
      puts "- #{course.name} (#{course.locations.first&.name})"
    end

    # Find courses with default values
    default_values = Course.where(
      "number_of_holes = 18 AND par = 72 AND yardage = 6500 AND green_fee = 100"
    )
    puts "\nCourses with default values: #{default_values.count}"
    default_values.each do |course|
      puts "- #{course.name} (#{course.locations.first&.name})"
    end

    # Find courses with minimal tags
    minimal_tags = Course.where("array_length(course_tags, 1) <= 2")
    puts "\nCourses with minimal tags: #{minimal_tags.count}"
    minimal_tags.each do |course|
      puts "- #{course.name} (#{course.locations.first&.name}) - Tags: #{course.course_tags.join(', ')}"
    end

    # Summary
    total_courses = Course.count
    puts "\n=== Summary ==="
    puts "Total courses: #{total_courses}"
    puts "Courses needing description: #{minimal_courses.count} (#{(minimal_courses.count.to_f / total_courses * 100).round(1)}%)"
    puts "Courses from Google Places: #{google_imported.count} (#{(google_imported.count.to_f / total_courses * 100).round(1)}%)"
    puts "Courses with default values: #{default_values.count} (#{(default_values.count.to_f / total_courses * 100).round(1)}%)"
    puts "Courses with minimal tags: #{minimal_tags.count} (#{(minimal_tags.count.to_f / total_courses * 100).round(1)}%)"
  end

  # lib/tasks/db_push.rake
  desc "Dump local dev DB for pushing to production"
  task dump: :environment do
    puts "\n=== Creating Database Dump ==="

    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    dump_file = Rails.root.join("tmp", "dev_to_prod_#{timestamp}.dump")

    config = ActiveRecord::Base.connection_db_config.configuration_hash

    cmd_parts = [
      "pg_dump",
      "--format=custom",
      "--no-owner",
      "--no-acl",
      "--clean",
      "--if-exists",
      "--file=#{dump_file}",
      config[:database]
    ]

    cmd_parts.insert(1, "--host=#{config[:host]}") if config[:host]
    cmd_parts.insert(1, "--port=#{config[:port]}") if config[:port]
    cmd_parts.insert(1, "--username=#{config[:username]}") if config[:username]

    cmd = cmd_parts.join(" ")

    puts "Running dump command:"
    puts cmd

    unless system(cmd)
      puts "❌ pg_dump failed."
      exit 1
    end

    puts "\n✅ Dump created: #{dump_file}"
    puts "\n=== Next Step: Upload and Restore to Production ==="

    puts <<~INSTRUCTIONS

      1. Copy the file to your production server:

         scp #{dump_file} your-server:/tmp/

      2. SSH into your production server and run:

         pg_restore --verbose --clean --no-acl --no-owner \\
           --dbname="postgres://[username]:[password]@[host]/[db_name]" \\
           /tmp/#{File.basename(dump_file)}

      Replace the values above with your actual Render credentials.

    INSTRUCTIONS
end

end 