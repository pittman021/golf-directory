require 'csv'

class CsvGolfImportService
  def initialize(csv_file_path = nil)
    @csv_file_path = csv_file_path || Rails.root.join('tmp', 'courses.csv')
  end

  def import_sample_courses(limit = 10)
    puts "🏌️ IMPORTING SAMPLE COURSES FROM LOCAL CSV"
    puts "=" * 50
    puts "📋 Goal: Import #{limit} courses from local CSV file"
    puts "📋 Source: #{@csv_file_path}"
    puts
    
    unless File.exist?(@csv_file_path)
      puts "❌ CSV file not found at: #{@csv_file_path}"
      puts "💡 Please place your CSV file at this location or specify the correct path"
      return 0
    end
    
    initial_count = Course.count
    puts "📊 Starting with #{initial_count} courses in database"
    puts
    
    imported_count = 0
    skipped_count = 0
    
    CSV.foreach(@csv_file_path, headers: true).each_with_index do |row, index|
      break if imported_count >= limit
      
      # Skip courses with undefined coordinates
      if row['latLng'] == 'undefined' || row['latLng'].nil? || row['latLng'].empty?
        puts "   ⏭️ Skipping #{row['name']} - no coordinates"
        skipped_count += 1
        next
      end
      
      # Parse coordinates
      coords = parse_coordinates(row['latLng'])
      unless coords
        puts "   ⏭️ Skipping #{row['name']} - invalid coordinates"
        skipped_count += 1
        next
      end
      
      # Check for duplicates
      if Course.where("LOWER(name) = ?", row['name'].downcase).exists?
        puts "   ⏭️ Skipping #{row['name']} - already exists"
        skipped_count += 1
        next
      end
      
      # Create course (ignoring the original _id field)
      if create_course_from_csv(row, coords)
        puts "   ✅ Imported: #{row['name']} (#{row['city']}, #{row['state']})"
        imported_count += 1
      else
        puts "   ❌ Failed: #{row['name']}"
        skipped_count += 1
      end
    end
    
    final_count = Course.count
    puts
    puts "🎯 CSV IMPORT RESULTS:"
    puts "=" * 25
    puts "   Imported: #{imported_count} courses"
    puts "   Skipped:  #{skipped_count} courses"
    puts "   Total:    #{final_count} courses (+#{final_count - initial_count})"
    puts
    puts "✅ CSV import complete! Ready for Google Places enrichment."
    
    imported_count
  end

  private

  def parse_coordinates(lat_lng_string)
    return nil unless lat_lng_string
    
    # Parse format: "39.877228,-77.009354"
    coords = lat_lng_string.split(',')
    return nil unless coords.length == 2
    
    begin
      lat = coords[0].to_f
      lng = coords[1].to_f
      
      # Basic validation - ensure coordinates are reasonable for US
      return nil if lat < 20 || lat > 70 || lng < -180 || lng > -60
      
      { latitude: lat, longitude: lng }
    rescue
      nil
    end
  end

  def create_course_from_csv(row, coordinates)
    # Find state record
    state_record = State.find_by(name: row['state'])
    unless state_record
      puts "     ⚠️ State '#{row['state']}' not found"
      return false
    end
    
    # Create course with our own ID system (ignoring original _id)
    course = Course.new(
      name: row['name'],
      latitude: coordinates[:latitude],
      longitude: coordinates[:longitude],
      state_id: state_record.id,
      description: "#{row['city']}, #{row['state']}",
      course_type: :public_course,
      number_of_holes: 18,
      par: 72,
      yardage: 6500,
      green_fee: 75,
      phone: "Pending Google enrichment",
      website_url: "Pending Google enrichment",
      course_tags: ["csv-import"],
      notes: "Imported from local CSV - Awaiting Google Places enrichment"
    )
    
    course.save
  end
end 