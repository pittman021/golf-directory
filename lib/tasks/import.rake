# lib/tasks/import.rake
namespace :import do
    desc "Import locations from CSV"
    task locations: :environment do
      require 'csv'
      
      csv_file = Rails.root.join('lib', 'data', 'csv', 'locations.csv')
      puts "Importing locations from #{csv_file}"
      
      begin
        file = File.open(csv_file)
        results = LocationImportService.import(file)
        
        puts "Import completed:"
        puts "Created: #{results[:created]}"
        puts "Updated: #{results[:updated]}"
        puts "Failed: #{results[:failed]}"
        if results[:errors].any?
          puts "\nErrors:"
          results[:errors].each { |error| puts "- #{error}" }
        end
      rescue Errno::ENOENT
        puts "Error: File #{csv_file} not found"
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace
      end
    end
  
    desc "Import courses from CSV"
    task courses: :environment do
      require 'csv'
      
      csv_file = Rails.root.join('lib', 'data', 'csv', 'courses.csv')
      puts "Importing courses from #{csv_file}"
      
      begin
        file = File.open(csv_file)
        results = CourseImportService.import(file)
        
        puts "Import completed:"
        puts "Created: #{results[:created]}"
        puts "Updated: #{results[:updated]}"
        puts "Failed: #{results[:failed]}"
        if results[:errors].any?
          puts "\nErrors:"
          results[:errors].each { |error| puts "- #{error}" }
        end
      rescue Errno::ENOENT
        puts "Error: File #{csv_file} not found"
      rescue => e
        puts "Error: #{e.message}"
        puts e.backtrace
      end
    end
  
    desc "Import both locations and courses from CSV"
    task all: :environment do
      Rake::Task["import:locations"].invoke
      puts "\n"
      Rake::Task["import:courses"].invoke
      
      puts "\nUpdating location statistics..."
      Location.find_each do |location|
        location.update_avg_green_fee
      end
      puts "Done!"
    end
  end

namespace :export do
  desc "Export locations to CSV"
  task locations: :environment do
    require 'csv'
    
    csv_file = Rails.root.join('lib', 'data', 'csv', 'locations.csv')
    puts "Exporting locations to #{csv_file}"
    
    headers = %w[
      name 
      description 
      region 
      state 
      country 
      latitude 
      longitude 
      best_months
      nearest_airports 
      weather_info 
      avg_lodging_cost_per_night
      avg_green_fee
      estimated_trip_cost
      tags
    ]
    
    CSV.open(csv_file, 'w') do |csv|
      csv << headers
      
      Location.find_each do |location|
        row = [
          location.name,
          location.description,
          location.region,
          location.state,
          location.country,
          location.latitude,
          location.longitude,
          location.best_months,
          location.nearest_airports,
          location.weather_info,
          location.avg_lodging_cost_per_night,
          location.avg_green_fee,
          location.estimated_trip_cost,
          location.tags&.join(',')
        ]
        csv << row
      end
    end
    puts "Export completed!"
  end

  desc "Export courses to CSV"
  task courses: :environment do
    require 'csv'
    
    csv_file = Rails.root.join('lib', 'data', 'csv', 'courses.csv')
    puts "Exporting courses to #{csv_file}"
    
    headers = %w[
      name 
      location_name 
      description 
      course_type 
      number_of_holes 
      green_fee 
      yardage 
      par 
      layout_tags 
      website_url 
      notes
    ]
    
    CSV.open(csv_file, 'w') do |csv|
      csv << headers
      
      Course.includes(:locations).find_each do |course|
        row = [
          course.name,
          course.locations.first&.name,
          course.description,
          course.course_type,
          course.number_of_holes,
          course.green_fee,
          course.yardage,
          course.par,
          course.layout_tags&.join(','),
          course.website_url,
          course.notes
        ]
        csv << row
      end
    end
    puts "Export completed!"
  end

  desc "Export both locations and courses to CSV"
  task all: [:locations, :courses]
end