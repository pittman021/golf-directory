namespace :friendly_id do
  desc "Generate slugs for existing records"
  task generate_slugs: :environment do
    puts "Generating slugs for courses..."
    Course.find_each do |course|
      begin
        # Clear existing slug and let FriendlyId generate a new one
        course.slug = nil
        course.save!
        print "."
      rescue => e
        puts "\nError processing course #{course.id} (#{course.name}): #{e.message}"
      end
    end
    puts "\nDone with courses!"

    puts "Generating slugs for locations..."
    Location.find_each do |location|
      begin
        # Clear existing slug and let FriendlyId generate a new one
        location.slug = nil
        location.save!
        print "."
      rescue => e
        puts "\nError processing location #{location.id} (#{location.name}): #{e.message}"
      end
    end
    puts "\nDone with locations!"
  end
end 