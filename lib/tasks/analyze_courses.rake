namespace :courses do
  desc "Analyze courses with specific notes"
  task analyze: :environment do
    puts "\nAnalyzing courses..."
    
    # Find courses with the specific note
    courses = Course.where(notes: "Automatically imported from Google Places API")

    
    if courses.any?
      puts "\nFound #{courses.count} courses with 'Automatically imported from Google Places API' in notes:"
      puts "\nCourse Details:"
      puts "---------------"
      
      courses.each do |course|
        puts "\nCourse: #{course.name}"
        puts "ID: #{course.id}"
        puts "Location: #{course.locations.first&.name}"
        puts "Course Type: #{course.course_type}"
        puts "Green Fee: #{number_to_currency(course.green_fee)}"
        puts "Notes: #{course.notes}"
        puts "---------------"
      end
      
      puts "\nSummary:"
      puts "Total courses found: #{courses.count}"
      puts "Course types breakdown:"
      courses.group_by(&:course_type).each do |type, type_courses|
        puts "  #{type}: #{type_courses.count}"
      end
    else
      puts "\nNo courses found with 'Automatically imported from Google Places API' in notes."
    end
  end
end 