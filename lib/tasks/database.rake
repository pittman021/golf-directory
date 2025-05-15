namespace :db do
  desc "Export full database data for production import"
  task export: :environment do
    # Check if we have a valid database connection
    begin
      ActiveRecord::Base.connection
    rescue => e
      puts "Error: Unable to connect to database"
      puts "Please ensure your database is properly configured in database.yml or DATABASE_URL is set"
      exit 1
    end

    puts "\n=== Exporting Full Database Data ==="
    
    # Create output directory if it doesn't exist
    FileUtils.mkdir_p(Rails.root.join('tmp'))
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    dump_file = Rails.root.join('tmp', "golf_directory_#{timestamp}.dump")
    
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
      puts "\n=== Export Complete ==="
      puts "Database dump saved to: #{dump_file}"
      puts 
      puts "To import to production:"
      puts "1. Copy this file to your production server"
      puts "2. Run: pg_restore -d <database_name> #{File.basename(dump_file)}"
      puts "   or within Rails: rails dbconsole production < #{File.basename(dump_file)}"
    else
      puts "\nError: Database export failed"
      exit 1
    end
  end
end 