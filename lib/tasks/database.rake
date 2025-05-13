namespace :db do
  desc "Export full locations and courses data for production import"
  task export: :environment do
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
end 