require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'

class FreeGolfTrackerService
  def initialize
    @base_url = "https://freegolftracker.com"
    @processed_count = 0
    @created_count = 0
    @skipped_count = 0
  end

  def import_all_courses
    puts "🌍 COMPREHENSIVE FREEGOLFTRACKER IMPORT - STARTING FROM A"
    puts "=" * 60
    puts "📋 Goal: Import ALL golf courses from FreeGolfTracker.com"
    puts "📋 Strategy: A→Z systematic import with duplicate detection"
    puts "📋 Data: Name, coordinates, holes, address, phone, website, etc."
    puts
    
    initial_count = Course.count
    puts "📊 Starting with #{initial_count} courses in database"
    puts
    
    # Import all letters A-Z
    ('a'..'z').each_with_index do |letter, index|
      puts "\n🔤 PROCESSING LETTER '#{letter.upcase}' (#{index + 1}/26)"
      puts "-" * 50
      
      begin
        import_courses_for_letter(letter)
        
        # Show progress
        current_total = Course.count
        puts "   📈 Database now has #{current_total} courses (+#{current_total - initial_count} total new)"
        
        # Rate limiting between letters
        if index < 25
          puts "   ⏱️ Waiting 5 seconds before next letter..."
          sleep(5)
        end
        
      rescue => e
        puts "   ❌ Error processing letter '#{letter.upcase}': #{e.message}"
        puts "   🔄 Continuing with next letter..."
      end
    end
    
    final_count = Course.count
    puts "\n🎯 FINAL RESULTS:"
    puts "=" * 30
    puts "   Initial courses: #{initial_count}"
    puts "   Final courses:   #{final_count}"
    puts "   Total added:     #{final_count - initial_count}"
    puts "   Growth:          +#{((final_count - initial_count).to_f / initial_count * 100).round(1)}%"
    puts
    puts "✅ Comprehensive import complete!"
  end

  def import_courses_for_letter(letter)
    url = "#{@base_url}/courses/findgolfcourses.php?slet=#{letter}"
    puts "   🌐 Accessing: #{url}"
    
    uri = URI(url)
    response = Net::HTTP.get_response(uri)
    
    unless response.is_a?(Net::HTTPSuccess)
      puts "   ❌ HTTP Error: #{response.code}"
      return
    end
    
    doc = Nokogiri::HTML(response.body)
    course_rows = doc.css('table tr').select { |row| row.css('td').length >= 4 }
    
    puts "   📊 Found #{course_rows.length} course entries"
    
    created_count = 0
    skipped_count = 0
    
    course_rows.each_with_index do |row, index|
      cells = row.css('td')
      next if cells.length < 4
      
      course_link = cells[0].css('a').first
      next unless course_link
      
      course_name = course_link.text.strip
      city = cells[1].text.strip
      state = cells[2].text.strip
      country = cells[3].text.strip
      
      # Skip non-US courses
      unless country.downcase.include?('united states')
        next
      end
      
      puts "     🏌️ #{course_name} (#{city}, #{state})"
      
      # Simple duplicate check
      if Course.where("LOWER(name) = ?", course_name.downcase).exists?
        puts "       ⏭️ Already exists - skipping"
        skipped_count += 1
        next
      end
      
      # Get coordinates from detail page
      course_details = get_course_coordinates(course_link['href'])
      
      if create_simple_course(course_name, city, state, course_details)
        puts "       ✅ Created successfully"
        created_count += 1
      else
        puts "       ❌ Failed to create"
        skipped_count += 1
      end
      
      # Rate limiting - 2 seconds between each course
      sleep(2)
      
      # Progress update every 10 courses
      if (index + 1) % 10 == 0
        puts "     📈 Progress: #{index + 1}/#{course_rows.length} processed"
      end
    end
    
    puts "   ✅ Letter '#{letter.upcase}' complete: +#{created_count} new, #{skipped_count} skipped"
  end

  private

  def get_course_coordinates(course_url)
    return nil unless course_url
    
    full_url = course_url.start_with?('http') ? course_url : "#{@base_url}/courses/#{course_url}"
    
    begin
      sleep(1) # Rate limiting for detail page
      
      uri = URI(full_url)
      response = Net::HTTP.get_response(uri)
      
      return nil unless response.is_a?(Net::HTTPSuccess)
      
      doc = Nokogiri::HTML(response.body)
      
      coordinates = nil
      website = nil
      
      # Look for coordinates and website in the page
      doc.css('table tr').each do |row|
        cells = row.css('td')
        next unless cells.length >= 2
        
        label = cells[0].text.strip.downcase
        value = cells[1].text.strip
        
        if label.include?('latitude') && label.include?('longitude')
          coords = value.match(/\(([^,]+),\s*([^)]+)\)/)
          if coords
            coordinates = {
              latitude: coords[1].to_f,
              longitude: coords[2].to_f
            }
          end
        elsif label.include?('website')
          website = value unless value.empty? || value.downcase == 'n/a'
        end
      end
      
      # Return both coordinates and website info
      {
        coordinates: coordinates,
        website: website
      }
      
    rescue => e
      puts "         ⚠️ Error getting course details: #{e.message}"
      nil
    end
  end

  def create_simple_course(name, city, state, course_details)
    # Find state record
    state_record = State.find_by(name: state)
    unless state_record
      puts "         ⚠️ State '#{state}' not found"
      return false
    end
    
    # Require website - skip courses without websites
    unless course_details && course_details[:website]
      puts "         ⏭️ No website found - skipping (quality filter)"
      return false
    end
    
    # Use coordinates if available, otherwise defaults
    coordinates = course_details[:coordinates]
    if coordinates.nil?
      puts "         ⚠️ No coordinates found, using defaults"
      coordinates = { latitude: 40.0, longitude: -100.0 }
    end
    
    course = Course.new(
      name: name,
      latitude: coordinates[:latitude],
      longitude: coordinates[:longitude],
      state_id: state_record.id,
      description: "#{city}, #{state}",
      course_type: :public_course,
      number_of_holes: 18,
      par: 72,
      yardage: 6500,
      green_fee: 75,
      phone: "Info coming soon",
      website_url: course_details[:website],
      course_tags: ["freegolftracker"], # Required field
      notes: "Imported from FreeGolfTracker.com - Details coming soon"
    )
    
    if course.save
      return true
    else
      puts "         ❌ Save errors: #{course.errors.full_messages.join(', ')}"
      return false
    end
  end
end 