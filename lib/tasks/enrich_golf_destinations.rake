namespace :enrich do
  desc "Enrich golf destinations with AI-generated content"
  task golf_destinations: :environment do
    puts "Starting golf destination enrichment process..."
    
    # Get just one location for testing
    location = Location.first
    
    if location.nil?
      puts "No locations found in the database. Please run the import task first."
      return
    end
    
    puts "Testing enrichment with location: #{location.name}, #{location.state}"
    
    begin
      # Check if OpenAI API key is present
      unless Rails.application.credentials.openai&.dig(:api_key)
        puts "Error: OpenAI API key is missing. Please add it to config/credentials.yml.enc under openai.api_key"
        return
      end

      # Initialize the enrichment service
      service = GolfDestinationEnrichmentService.new(location)
      
      # Run the enrichment process
      if service.enrich
        puts "\n✓ Successfully enriched #{location.name}"
        puts "\nGenerated Summary:"
        puts "-----------------"
        puts location.summary
      else
        puts "✗ Failed to enrich #{location.name}"
      end
      
    rescue OpenAI::Error => e
      puts "OpenAI API Error: #{e.message}"
      Rails.logger.error "OpenAI API Error for location #{location.id}: #{e.message}"
    rescue => e
      puts "Error processing #{location.name}: #{e.message}"
      Rails.logger.error "Error enriching location #{location.id}: #{e.message}"
    end
    
    puts "\nTest enrichment process completed!"
  end
end 