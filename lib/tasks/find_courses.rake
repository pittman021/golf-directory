# This file contains Rake tasks for finding and processing golf courses by location.
# 
# Tasks included:

# - golf:get_courses_for_all_states: Finds and processes golf courses for all 50 states
# - golf:get_courses_by_state[state_name]: Finds and processes golf courses for a specified state

require_relative "../data/state_coordinates"

namespace :golf do
  desc "Seed golf courses for a state using multiple centerpoints"
  task :get_courses_by_state, [:state_name] => :environment do |_, args|
    state = args[:state_name]
    unless STATE_COORDINATES[state]
      puts "❌ No coordinates found for #{state}. Add it to STATE_COORDINATES."
      exit
    end

    puts "📍 Starting seed for #{state}..."
    STATE_COORDINATES[state].each_with_index do |coord, i|
      puts "🔄 Point ##{i + 1} (#{coord[:lat]}, #{coord[:lng]})"
      FindCoursesByCoordinatesService.new(
        lat: coord[:lat],
        lng: coord[:lng],
        state: state
      ).find_and_seed
    end
    puts "✅ Finished seeding courses for #{state}!"
  end

  desc "Seed courses for all 50 states"
  task :get_courses_for_all_states => :environment do
    STATE_COORDINATES.each_key do |state|
      Rake::Task["golf:get_courses_by_state"].invoke(state)
      Rake::Task["golf:get_courses_by_state"].reenable
    end
  end
end
