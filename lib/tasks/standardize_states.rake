namespace :courses do
  desc "Standardize state names to their full names"
  task standardize_states: :environment do
    state_mapping = {
      'AZ' => 'Arizona',
      'CO' => 'Colorado',
      'OR' => 'Oregon',
      'TX' => 'Texas'
    }

    puts "Starting state standardization..."
    
    state_mapping.each do |abbrev, full_name|
      count = Location.where(state: abbrev).count
      if count > 0
        puts "Updating #{count} locations from #{abbrev} to #{full_name}"
        Location.where(state: abbrev).update_all(state: full_name)
      end
    end

    puts "State standardization complete!"
    puts "\nCurrent states in database:"
    puts Location.distinct.pluck(:state).sort
  end
end 