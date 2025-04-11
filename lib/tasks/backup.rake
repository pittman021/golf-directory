# This rake task provides database backup functionality.
# It creates compressed backups of the database and stores them in the db/backups directory.
#
# Usage:
#   rails db:backup           # Creates a backup with timestamp
#   rails db:backup[clean]    # Creates a backup and removes old backups
#
# Features:
# - Creates timestamped backups
# - Compresses backups
# - Stores backups in db/backups
# - Optional cleanup of old backups
# - Verbose output of backup process

namespace :db do
  desc "Backup the database to db/backups"
  task :backup, [:clean] => :environment do |t, args|
    # Ensure backups directory exists
    backup_dir = Rails.root.join('db', 'backups')
    FileUtils.mkdir_p(backup_dir)

    # Generate backup filename with timestamp
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    backup_file = backup_dir.join("golf_directory_#{timestamp}.dump")

    # Get database configuration
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    database = config[:database]

    puts "Starting database backup..."
    puts "Database: #{database}"
    puts "Backup file: #{backup_file}"

    # Build pg_dump command - using system authentication
    cmd = "pg_dump -Fc -v -Z 9 #{database} > #{backup_file}"

    # Execute backup
    if system(cmd)
      puts "Backup completed successfully!"
      puts "Backup saved to: #{backup_file}"
      
      # Clean up old backups if requested
      if args[:clean]
        puts "Cleaning up old backups..."
        # Keep last 5 backups
        backups = Dir.glob(backup_dir.join("*.dump")).sort_by { |f| File.mtime(f) }
        if backups.size > 5
          old_backups = backups[0...-5]
          old_backups.each do |backup|
            File.delete(backup)
            puts "Deleted old backup: #{backup}"
          end
        end
      end
    else
      puts "Backup failed!"
      exit 1
    end
  end
end 