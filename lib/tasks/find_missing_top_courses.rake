require 'fuzzy_match'
require 'timeout'

# Only load if the constant isn't already defined
load 'lib/golf_data/top_100_courses.rb' unless defined?(GolfData::TOP_COURSES)

namespace :courses do
  desc "Find top 100 courses that are missing from the database"
  task find_missing: :environment do
    puts "🔍 Looking for missing top 100 courses..."

    # Get all course names from the database
    puts "Fetching course names from database..."
    course_names_in_db = Course.all.pluck(:id, :name).map { |id, name| [id, name.strip.downcase] }
    puts "Found #{course_names_in_db.size} courses in database"

    # Initialize FuzzyMatch with a more efficient threshold
    matcher = FuzzyMatch.new(course_names_in_db, read: ->(pair) { pair[1] })
    missing_courses = []
    found_courses = []
    total_courses = GolfData::TOP_COURSES.size

    puts "\nComparing courses..."
    GolfData::TOP_COURSES.each_with_index do |top_course, index|
      print "\rProcessing course #{index + 1}/#{total_courses} (#{((index + 1.0) / total_courses * 100).round}%)"
      
      normalized_name = top_course[:name].strip.downcase
      
      begin
        Timeout.timeout(2) do  # Set 2 second timeout for each match attempt
          match_result = matcher.find_with_score(normalized_name)
          
          if match_result && match_result[1] > 0.5  # Only accept matches with >50% similarity
            found_courses << {
              name: top_course[:name],
              matched_with: match_result[0][1],  # Get the name from the pair
              db_id: match_result[0][0],         # Get the ID from the pair
              similarity: match_result[1]
            }
          else
            missing_courses << top_course
          end
        end
      rescue Timeout::Error
        puts "\n⚠️  Matching timed out for: #{top_course[:name]}"
        missing_courses << top_course
      end
    end
    puts "\n"  # New line after progress indicator

    # Report findings
    puts "\n📊 Summary:"
    puts "Total top 100 courses: #{total_courses}"
    puts "Found in database: #{found_courses.size}"
    puts "Missing from database: #{missing_courses.size}"

    if missing_courses.any?
      puts "\n❌ Missing Courses:"
      missing_courses.each do |course|
        puts "- #{course[:name]} (#{course[:state]})"
      end
    end

    if found_courses.any?
      puts "\n✅ Found Courses (with match scores):"
      found_courses.sort_by { |c| -c[:similarity] }.each do |course|
        puts "- #{course[:name]}"
        puts "  Matched with: #{course[:matched_with]} (similarity: #{course[:similarity].round(2)})"
        puts "  Database ID: #{course[:db_id]}"
      end
    end

    # Save missing courses to a file for reference
    if missing_courses.any?
      file_path = Rails.root.join('tmp', 'missing_top_courses.txt')
      File.open(file_path, 'w') do |file|
        file.puts "Missing Top 100 Courses (as of #{Time.current.strftime('%Y-%m-%d %H:%M:%S')})"
        file.puts "================================================="
        missing_courses.each do |course|
          file.puts "#{course[:name]} (#{course[:state]})"
        end
      end
      puts "\n📝 Missing courses list saved to: #{file_path}"
    end
  end
end 