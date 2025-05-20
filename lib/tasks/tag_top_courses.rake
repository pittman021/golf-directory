require 'fuzzy_match'

# Only load if the constant isn't already defined
load 'lib/golf_data/top_100_courses.rb' unless defined?(GolfData::TOP_COURSES)

namespace :courses do
  desc "Tag top 100 courses or create them via Google Places if missing"
  task tag_top_100: :environment do
    puts "🔍 Starting to tag top 100 courses..."

    # Initialize tracking arrays
    tagged_courses = []
    not_found_courses = []
    already_tagged_courses = []

    # Get all courses and normalize their names
    puts "Fetching all courses from database..."
    all_courses = Course.all.to_a
    
    GolfData::TOP_COURSES.each do |top_course|
      normalized_name = top_course[:name].strip.downcase.gsub(/\s+/, ' ')
      
      # Try to find an exact match (case insensitive)
      course = all_courses.find do |db_course|
        db_course.name.strip.downcase.gsub(/\s+/, ' ') == normalized_name
      end

      if course
        if course.course_tags.include?("top_100")
          already_tagged_courses << {
            name: course.name,
            id: course.id
          }
        else
          course.course_tags << "top_100"
          if course.save
            tagged_courses << {
              name: course.name,
              id: course.id
            }
          else
            puts "❌ Error saving #{course.name}: #{course.errors.full_messages.join(', ')}"
          end
        end
      else
        not_found_courses << top_course
      end
    end

    # Print summary
    puts "\n📊 Summary:"
    puts "Total top 100 courses processed: #{GolfData::TOP_COURSES.size}"
    puts "Already tagged: #{already_tagged_courses.size}"
    puts "Newly tagged: #{tagged_courses.size}"
    puts "Not found: #{not_found_courses.size}"

    if tagged_courses.any?
      puts "\n✅ Newly Tagged Courses:"
      tagged_courses.each do |course|
        puts "- #{course[:name]} (ID: #{course[:id]})"
      end
    end

    if already_tagged_courses.any?
      puts "\nℹ️ Already Tagged Courses:"
      already_tagged_courses.each do |course|
        puts "- #{course[:name]} (ID: #{course[:id]})"
      end
    end

    if not_found_courses.any?
      puts "\n❌ Courses Not Found:"
      not_found_courses.each do |course|
        puts "- #{course[:name]} (#{course[:state]})"
      end

      # Save not found courses to a file
      file_path = Rails.root.join('tmp', 'not_found_top_courses.txt')
      File.open(file_path, 'w') do |file|
        file.puts "Top 100 Courses Not Found in Database (as of #{Time.current.strftime('%Y-%m-%d %H:%M:%S')})"
        file.puts "================================================="
        not_found_courses.each do |course|
          file.puts "#{course[:name]} (#{course[:state]})"
        end
      end
      puts "\n📝 List of not found courses saved to: #{file_path}"
    end

    puts "\n🎯 Finished tagging top 100 courses."
  end
end
