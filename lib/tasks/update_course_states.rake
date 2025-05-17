namespace :courses do
  desc "Update course states based on their associated locations"
  task update_states_from_locations: :environment do
    puts "Starting to update course states from locations..."
    
    total_courses = Course.count
    updated_count = 0
    skipped_count = 0

    Course.find_each do |course|
      location = course.locations.first
      
      if location && location.state.present?
        course.update!(state: location.state)
        updated_count += 1
        puts "Updated course #{course.id} (#{course.name}) with state: #{location.state}"
      else
        skipped_count += 1
        puts "Skipped course #{course.id} (#{course.name}) - no location or state found"
      end
    end

    puts "\nUpdate complete!"
    puts "Total courses processed: #{total_courses}"
    puts "Courses updated: #{updated_count}"
    puts "Courses skipped: #{skipped_count}"
    
    puts "\nCurrent states in courses:"
    puts Course.distinct.pluck(:state).compact.sort
  end
end