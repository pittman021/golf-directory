namespace :golf_import do
  desc "Import 10 sample courses from local CSV file"
  task :csv_sample => :environment do
    puts "🚀 STARTING CSV SAMPLE IMPORT"
    puts "=" * 35
    puts "💡 Place your CSV file at: tmp/courses.csv"
    puts "💡 Or specify path: rake golf_import:csv_sample_with_path[/path/to/file.csv]"
    puts
    
    service = CsvGolfImportService.new
    service.import_sample_courses(10)
  end

  desc "Import courses from CSV file at specific path"
  task :csv_sample_with_path, [:csv_path] => :environment do |t, args|
    csv_path = args[:csv_path]
    
    unless csv_path
      puts "❌ Please provide CSV file path: rake golf_import:csv_sample_with_path[/path/to/file.csv]"
      exit 1
    end
    
    puts "🚀 STARTING CSV IMPORT FROM CUSTOM PATH"
    puts "=" * 45
    
    service = CsvGolfImportService.new(csv_path)
    service.import_sample_courses(10)
  end

  desc "Enrich courses with Google Places data"
  task :enrich_with_google => :environment do
    puts "🚀 STARTING GOOGLE PLACES ENRICHMENT"
    puts "=" * 40
    
    service = GooglePlacesEnrichmentService.new
    service.enrich_courses_with_google_data
  end

  desc "Complete workflow: Import CSV sample + Enrich with Google"
  task :csv_to_google_workflow => :environment do
    puts "🚀 COMPLETE CSV → GOOGLE WORKFLOW"
    puts "=" * 40
    puts "📋 Step 1: Import 10 courses from local CSV"
    puts "📋 Step 2: Enrich with Google Places data"
    puts "💡 Make sure CSV file is at: tmp/courses.csv"
    puts
    
    # Step 1: Import CSV
    csv_service = CsvGolfImportService.new
    imported = csv_service.import_sample_courses(10)
    
    if imported && imported > 0
      puts "\n⏱️ Waiting 3 seconds before Google enrichment..."
      sleep(3)
      
      # Step 2: Enrich with Google
      google_service = GooglePlacesEnrichmentService.new
      google_service.enrich_courses_with_google_data
    else
      puts "\n❌ No courses imported, skipping Google enrichment"
    end
    
    puts "\n🎉 WORKFLOW COMPLETE!"
  end

  desc "Import all golf courses from FreeGolfTracker.com (A-Z)"
  task :freegolftracker_all => :environment do
    puts "🚀 STARTING COMPREHENSIVE FREEGOLFTRACKER IMPORT"
    puts "=" * 55
    
    service = FreeGolfTrackerService.new
    service.import_all_courses
  end

  desc "Import courses from FreeGolfTracker for specific letter (e.g., 'a')"
  task :freegolftracker_letter, [:letter] => :environment do |t, args|
    letter = args[:letter]&.downcase
    
    unless letter && letter.match?(/^[a-z]$/)
      puts "❌ Please provide a single letter: rake golf_import:freegolftracker_letter[a]"
      exit 1
    end
    
    puts "🔤 IMPORTING FREEGOLFTRACKER COURSES FOR LETTER '#{letter.upcase}'"
    puts "=" * 60
    
    initial_count = Course.count
    puts "📊 Starting with #{initial_count} courses in database"
    puts
    
    service = FreeGolfTrackerService.new
    service.import_courses_for_letter(letter)
    
    final_count = Course.count
    puts
    puts "🎯 RESULTS:"
    puts "   Before: #{initial_count} courses"
    puts "   After:  #{final_count} courses"
    puts "   Added:  #{final_count - initial_count} courses"
  end

  desc "Test import with first few courses from letter 'a'"
  task :test_import => :environment do
    puts "🧪 TESTING FREEGOLFTRACKER IMPORT WITH LETTER 'A'"
    puts "=" * 50
    
    initial_count = Course.count
    puts "📊 Starting with #{initial_count} courses in database"
    puts
    
    service = FreeGolfTrackerService.new
    service.import_courses_for_letter('a')
    
    final_count = Course.count
    puts
    puts "🎯 TEST RESULTS:"
    puts "   Before: #{initial_count} courses"
    puts "   After:  #{final_count} courses"
    puts "   Added:  #{final_count - initial_count} courses"
    
    if final_count > initial_count
      puts "\n📋 RECENTLY ADDED COURSES:"
      Course.order(created_at: :desc).limit(5).each do |course|
        puts "   • #{course.name} (#{course.description})"
      end
    end
  end

  desc "Test Google Places API data for one course"
  task :test_google_data => :environment do
    puts "🔍 TESTING GOOGLE PLACES API DATA"
    puts "=" * 40
    
    # Get one course that needs enrichment
    course = Course.where(website_url: "Pending Google enrichment").first
    
    if course
      puts "📍 Testing with: #{course.name} (#{course.description})"
      puts
      
      service = GooglePlacesEnrichmentService.new
      service.enrich_courses_with_google_data([course])
    else
      puts "❌ No courses found that need enrichment"
      puts "💡 Import some CSV courses first with: rake golf_import:csv_sample"
    end
  end
end 