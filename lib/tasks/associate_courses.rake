namespace :golf do
  desc "Associate courses with Ponte Vedra Beach location"
  task :associate_ponte_vedra_courses => :environment do
    location = Location.find_by(name: 'Ponte Vedra Beach')
    if location.nil?
      puts "❌ Ponte Vedra Beach location not found!"
      exit
    end

    course_names = [
      'Jacksonville Beach Golf Club',
      'San Jose Country Club',
      'San Jose Municipal Golf Course'
    ]

    courses = Course.where(name: course_names)
    
    if courses.empty?
      puts "❌ No courses found to associate!"
      exit
    end

    courses.each do |course|
      unless location.courses.include?(course)
        location.courses << course
        puts "✅ Associated #{course.name} with Ponte Vedra Beach"
      else
        puts "ℹ️ #{course.name} is already associated with Ponte Vedra Beach"
      end
    end

    puts "\n✅ Finished associating courses with Ponte Vedra Beach!"
  end
end 