# lib/tasks/update_location_costs.rake
namespace :locations do
    desc "Update location costs and fees"
    task update_costs: :environment do
      Location.find_each do |location|
        # Calculate average green fee from associated courses
        avg_fee = location.courses.average(:green_fee).to_i
        location.update_columns(
          avg_green_fee: avg_fee,
          avg_lodging_cost_per_night: 200, # Default value, adjust as needed
          estimated_trip_cost: (200 * 3) + (avg_fee * 3), # 3 nights lodging + 3 rounds
          tags: ['coastal'], # Default tag, adjust as needed
          summary: location.description # Use existing description as summary
        )
        puts "Updated #{location.name}"
      end
    end
  end