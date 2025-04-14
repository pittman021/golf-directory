namespace :migrate do
  desc "Restructure and fix the format of location summaries"
  task location_summaries: :environment do
    puts "Starting location summary data migration..."
    
    # Track our changes
    locations_processed = 0
    locations_updated = 0
    locations_with_errors = 0
    
    Location.find_each do |location|
      locations_processed += 1
      puts "Processing location #{location.id} - #{location.name}..."
      
      if location.summary.blank?
        puts "  No summary data found, skipping."
        next
      end
      
      begin
        current_summary = nil
        new_summary = nil
        
        # Case 1: Try to eval if it's a Ruby hash format with =>
        if location.summary.include?('=>')
          begin
            current_summary = eval(location.summary)
            new_summary = current_summary.to_json
            puts "  Converted Ruby hash to JSON."
          rescue StandardError => e
            puts "  Error evaluating Ruby hash: #{e.message}"
          end
        end
        
        # Case 2: Try to parse as JSON
        if current_summary.nil? && !location.summary.start_with?('"') && (location.summary.start_with?('{') || location.summary.start_with?('['))
          begin
            current_summary = JSON.parse(location.summary)
            new_summary = location.summary # Already JSON
            puts "  Already in JSON format."
          rescue JSON::ParserError => e
            puts "  Error parsing JSON: #{e.message}"
          end
        end
        
        # Case 3: It's a simple text string, convert to proper structured JSON
        if current_summary.nil?
          puts "  Converting plain text to structured JSON..."
          new_summary = {
            'destination_overview' => location.summary,
            'golf_experience' => '',
            'travel_information' => '',
            'local_attractions' => '',
            'practical_tips' => ''
          }.to_json
        end
        
        # Save the updated summary
        if new_summary
          location.update_column(:summary, new_summary)
          locations_updated += 1
          puts "  Successfully updated summary format."
        else
          locations_with_errors += 1
          puts "  Failed to update summary format."
        end
        
      rescue StandardError => e
        locations_with_errors += 1
        puts "  Error processing location: #{e.message}"
        puts "  #{e.backtrace.first}"
      end
    end
    
    puts "\nMigration complete!"
    puts "Locations processed: #{locations_processed}"
    puts "Locations updated: #{locations_updated}"
    puts "Locations with errors: #{locations_with_errors}"
  end
end 