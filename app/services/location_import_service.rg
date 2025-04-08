# app/services/location_import_service.rb
require 'csv'

class LocationImportService
  def self.import(file)
    results = { created: 0, updated: 0, failed: 0, errors: [] }
    
    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      begin
        # Find or initialize location
        location = Location.find_or_initialize_by(name: row[:name])
        
        # Update location attributes with all available fields
        location.assign_attributes(
          name: row[:name],
          description: row[:description],
          region: row[:region],
          state: row[:state],
          country: row[:country],
          latitude: row[:latitude],
          longitude: row[:longitude],
          avg_temperature: row[:avg_temperature],
          peak_season_start: row[:peak_season_start],
          peak_season_end: row[:peak_season_end],
          avg_lodging_cost: row[:avg_lodging_cost],
          website_url: row[:website_url]
        )

        if location.new_record?
          if location.save
            results[:created] += 1
          else
            results[:errors] << "Failed to create location '#{row[:name]}': #{location.errors.full_messages.join(', ')}"
            results[:failed] += 1
          end
        else
          if location.save
            results[:updated] += 1
          else
            results[:errors] << "Failed to update location '#{row[:name]}': #{location.errors.full_messages.join(', ')}"
            results[:failed] += 1
          end
        end
      rescue => e
        results[:errors] << "Error processing row for '#{row[:name]}': #{e.message}"
        results[:failed] += 1
      end
    end
    
    results
  end
end