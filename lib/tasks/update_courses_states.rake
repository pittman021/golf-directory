namespace :courses do
  desc "Update courses with state_id based on existing state field"
  task update_state_ids: :environment do
    puts "Starting to update courses with state relationships..."
    
    # Get all courses with state values
    courses = Course.where.not(state: [nil, ''])
    
    # Update courses with state_id
    courses.find_each do |course|
      state = State.find_by(name: course.state)
      if state
        course.update_column(:state_id, state.id)
        print "."
      else
        puts "\nWarning: Could not find state '#{course.state}' for course '#{course.name}'"
      end
    end
    
    puts "\nFinished updating courses with state relationships!"
  end
end 