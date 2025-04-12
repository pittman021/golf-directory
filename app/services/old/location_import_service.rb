require 'csv'

module Old
  class LocationImportService
    def self.import(file_path)
      CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
        location = Location.find_or_initialize_by(name: row[:name])
        
        location.assign_attributes(
          description: row[:description],
          region: row[:region],
          state: row[:state],
          country: row[:country],
          latitude: row[:latitude],
          longitude: row[:longitude],
          best_months: row[:best_months],
          nearest_airports: row[:nearest_airports],
          weather_info: row[:weather_info],
          avg_lodging_cost_per_night: row[:avg_lodging_cost_per_night],
          avg_green_fee: row[:avg_green_fee],
          estimated_trip_cost: row[:estimated_trip_cost],
          tags: row[:tags].to_s.split(',').map(&:strip).reject(&:empty?),
          summary: row[:summary]
        )

        if location.save
          puts "Successfully imported location: #{location.name}"
        else
          puts "Failed to import location #{location.name}: #{location.errors.full_messages.join(', ')}"
        end
      rescue StandardError => e
        puts "Error processing row for '#{row[:name]}': #{e.message}"
      end
    end
  end
end