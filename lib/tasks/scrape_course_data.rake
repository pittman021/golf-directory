require 'nokogiri'
require 'open-uri'
require 'timeout'
require 'json'

# Load the golf amenities configuration
require_relative '../../config/golf_amenities'
require_relative '../../config/standardized_amenities'

namespace :courses do
  desc "Run enhanced scraping on courses with real websites and blank amenities"
  task scrape_all_remaining_courses: :environment do
    puts "🕷️ Starting targeted web scraping for courses with blank amenities..."
    puts "Target: Courses with real websites (excluding 'Pending Google Enrichment') that have blank amenities"
    puts "Focus: Amenities extraction from golf course websites"
    puts "=" * 70
    
    # Get list of previously failed course IDs
    failed_course_ids = get_failed_course_ids_from_log
    puts "📋 Excluding #{failed_course_ids.count} previously failed courses"
    
    # Create log file for failed scrapes
    log_file = Rails.root.join('log', 'failed_scrapes.log')
    
    # Find courses with REAL websites that have blank amenities
    base_query = Course.where.not(website_url: nil)
                      .where("website_url != ''")
                      .where("website_url NOT LIKE '%Pending%' AND website_url NOT LIKE '%No website%'")
                      .where("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL")
    
    # Exclude previously failed courses
    if failed_course_ids.any?
      base_query = base_query.where.not(id: failed_course_ids)
    end
    
    courses_to_scrape = base_query.limit(500) # Process in larger batches for efficiency
    
    total_eligible = base_query.count
    puts "Found #{courses_to_scrape.count} courses to scrape in this batch"
    puts "Total eligible courses with blank amenities: #{total_eligible}"
    puts "Previously failed courses excluded: #{failed_course_ids.count}"
    puts "Failed scrapes will be logged to: #{log_file}"
    puts ""
    
    scraped_count = 0
    failed_count = 0
    failed_courses = []
    
    courses_to_scrape.find_each.with_index do |course, index|
      puts "\n#{index + 1}/#{courses_to_scrape.count}: Scraping amenities for #{course.name}..."
      puts "  State: #{course.state&.name || course.state || 'Unknown'}"
      puts "  Website: #{course.website_url}"
      puts "  Current amenities: #{course.amenities&.any? ? course.amenities.join(', ') : 'BLANK'}"
      
      begin
        scraped_data = scrape_course_website_enhanced(course.website_url, course.name)
        
        if scraped_data.any?
          update_course_with_scraped_data(course, scraped_data)
          scraped_count += 1
          puts "  ✅ Successfully scraped data for #{course.name}"
          
          # Show what was found, with emphasis on amenities
          if scraped_data[:amenities]&.any?
            puts "  🏌️ AMENITIES FOUND: #{scraped_data[:amenities].join(', ')}"
          else
            puts "  🏌️ Amenities: Not found"
          end
          
          puts "  📞 Phone: #{scraped_data[:phone] || 'Not found'}"
          puts "  📧 Email: #{scraped_data[:email] || 'Not found'}"
          puts "  📝 Description: #{scraped_data[:description] ? "#{scraped_data[:description].length} chars" : 'Not found'}"
          puts "  🎯 Par: #{scraped_data[:par] || 'Not found'}"
          puts "  📏 Yardage: #{scraped_data[:yardage] || 'Not found'}"
          puts "  🕳️ Holes: #{scraped_data[:number_of_holes] || 'Not found'}"
        else
          puts "  ⚠️ No useful data found for #{course.name}"
          # Log as a failed scrape - website loads but no useful data
          failed_courses << {
            course: course,
            error: "No useful data found",
            error_type: "no_data"
          }
        end
        
        # Be respectful with delays - reduced since we're hitting different sites
        sleep(0.5)
        
      rescue StandardError => e
        failed_count += 1
        error_message = e.message
        error_type = categorize_error(error_message)
        
        puts "  ❌ Error scraping #{course.name}: #{error_message}"
        
        # Log the failed scrape
        failed_courses << {
          course: course,
          error: error_message,
          error_type: error_type
        }
      end
    end
    
    # Write failed scrapes to log file
    if failed_courses.any?
      log_failed_scrape(failed_courses)
    end
    
    puts "\n📊 Amenities Scraping Summary:"
    puts "Successfully scraped: #{scraped_count} courses"
    puts "Failed to scrape: #{failed_count} courses"
    if failed_courses.any?
      puts "No data found: #{failed_courses.count { |f| f[:error_type] == 'no_data' }} courses"
      puts "Connection errors: #{failed_courses.count { |f| f[:error_type] == 'connection_failed' }} courses"
      puts "Timeout errors: #{failed_courses.count { |f| f[:error_type] == 'timeout' }} courses"
    end
    puts "Total processed: #{scraped_count + failed_count} courses"
    puts "Total eligible remaining: #{total_eligible - courses_to_scrape.count} courses"
    
    puts "\n💡 Run again to continue scraping more courses with blank amenities."
    puts "📋 Check #{log_file} for courses that need website URL corrections."
    puts "🎯 This focused approach targets amenities extraction from real golf course websites."
  end
  
  desc "Enrich only top 100 courses with premium AI-generated content"
  task enrich_top_100: :environment do
    puts "🏆 Starting premium enrichment for top 100 courses only..."
    
    # Find top 100 courses that need enrichment
    top_100_courses = Course.where("'top_100' = ANY(course_tags)")
                           .where("(description IS NULL OR LENGTH(description) < 100) OR 
                                   (notes IS NULL OR LENGTH(notes) < 50) OR 
                                   (summary IS NULL OR summary = '{}' OR summary = '')")
                           .limit(10) # Process in small batches for cost control
    
    puts "Found #{top_100_courses.count} top 100 courses needing premium enrichment"
    
    enriched_count = 0
    failed_count = 0
    
    top_100_courses.find_each.with_index do |course, index|
      puts "\n#{index + 1}/#{top_100_courses.count}: Premium enriching #{course.name}..."
      
      begin
        # Use the full GetCourseInfoService for detailed enrichment
        service = GetCourseInfoService.new(course)
        result = service.gather_info
        
        if result.present?
          course.reload
          enriched_count += 1
          puts "  ✅ Successfully enriched #{course.name}"
          puts "  📝 Description: #{course.description&.length || 0} characters"
          puts "  📋 Notes: #{course.notes&.length || 0} characters"
          puts "  🏷️ Tags: #{course.course_tags.join(', ')}"
        else
          puts "  ⚠️ No enrichment data returned for #{course.name}"
        end
        
        # Longer delay for expensive AI calls
        sleep(5)
        
      rescue StandardError => e
        failed_count += 1
        puts "  ❌ Error enriching #{course.name}: #{e.message}"
      end
    end
    
    puts "\n📊 Premium Enrichment Summary:"
    puts "Successfully enriched: #{enriched_count} top 100 courses"
    puts "Failed to enrich: #{failed_count} courses"
    puts "Total processed: #{enriched_count + failed_count} courses"
  end
  
  desc "Show scraping and enrichment statistics"
  task scraping_stats: :environment do
    puts "📈 Course Data Collection Statistics"
    puts "=" * 60
    
    total_courses = Course.count
    courses_with_real_websites = Course.where.not(website_url: nil)
                                      .where("website_url != ''")
                                      .where("website_url NOT LIKE '%Pending%' AND website_url NOT LIKE '%No website%'")
                                      .count
    courses_with_pending = Course.where("website_url LIKE '%Pending%'").count
    top_100_courses = Course.where("'top_100' = ANY(course_tags)").count
    
    puts "\n🌐 Website Coverage:"
    puts "Total courses: #{total_courses}"
    puts "Courses with real websites: #{courses_with_real_websites} (#{(courses_with_real_websites.to_f / total_courses * 100).round(1)}%)"
    puts "Courses with 'Pending' URLs: #{courses_with_pending} (#{(courses_with_pending.to_f / total_courses * 100).round(1)}%)"
    puts "Top 100 courses: #{top_100_courses}"
    
    # Check basic data coverage
    puts "\n📞 Basic Data Coverage:"
    phone_coverage = Course.where.not(phone: nil).where("phone != ''").count
    email_coverage = Course.where.not(email: nil).where("email != ''").count
    green_fee_coverage = Course.where.not(green_fee: nil).where("green_fee != 100").count
    
    puts "Phone numbers: #{phone_coverage} (#{(phone_coverage.to_f / total_courses * 100).round(1)}%)"
    puts "Email addresses: #{email_coverage} (#{(email_coverage.to_f / total_courses * 100).round(1)}%)"
    puts "Green fees (non-default): #{green_fee_coverage} (#{(green_fee_coverage.to_f / total_courses * 100).round(1)}%)"
    
    # Check amenities coverage
    puts "\n🏌️ Amenities Coverage:"
    amenities_coverage = Course.where.not("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL").count
    real_websites_with_amenities = Course.where.not(website_url: nil)
                                         .where("website_url != ''")
                                         .where("website_url NOT LIKE '%Pending%' AND website_url NOT LIKE '%No website%'")
                                         .where.not("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL")
                                         .count
    
    puts "Courses with amenities: #{amenities_coverage} (#{(amenities_coverage.to_f / total_courses * 100).round(1)}%)"
    puts "Real websites with amenities: #{real_websites_with_amenities}/#{courses_with_real_websites} (#{(real_websites_with_amenities.to_f / courses_with_real_websites * 100).round(1)}%)"
    
    # Check enrichment coverage
    puts "\n🎯 Enrichment Coverage:"
    good_descriptions = Course.where("LENGTH(description) > 100").count
    good_notes = Course.where("LENGTH(notes) > 50").count
    
    puts "Good descriptions (>100 chars): #{good_descriptions} (#{(good_descriptions.to_f / total_courses * 100).round(1)}%)"
    puts "Good notes (>50 chars): #{good_notes} (#{(good_notes.to_f / total_courses * 100).round(1)}%)"
    
    # Top 100 specific stats
    puts "\n🏆 Top 100 Course Status:"
    top_100_with_good_descriptions = Course.where("'top_100' = ANY(course_tags)")
                                          .where("LENGTH(description) > 100").count
    top_100_with_websites = Course.where("'top_100' = ANY(course_tags)")
                                 .where.not(website_url: nil)
                                 .where("website_url != ''").count
    
    puts "Top 100 with good descriptions: #{top_100_with_good_descriptions}/#{top_100_courses}"
    puts "Top 100 with websites: #{top_100_with_websites}/#{top_100_courses}"
    
    # Scraping targets
    puts "\n🎯 Current Scraping Targets:"
    blank_amenities = Course.where.not(website_url: nil)
                           .where("website_url != ''")
                           .where("website_url NOT LIKE '%Pending%' AND website_url NOT LIKE '%No website%'")
                           .where("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL")
                           .count
    
    puts "Courses with real websites needing amenities: #{blank_amenities}"
    
    puts "\n💡 Recommendations:"
    if blank_amenities > 0
      puts "1. Run 'rails courses:scrape_all_remaining_courses' to extract amenities from real websites"
    end
    if top_100_with_good_descriptions < top_100_courses
      puts "2. Run 'rails courses:enrich_top_100' for premium content on top courses"
    end
    puts "3. Focus scraping efforts on courses with real websites but missing amenities"
  end
  
  private
  
  # Standardized failed URL tracking system
  def get_failed_course_ids_from_log
    failed_course_ids = []
    simple_log_file = Rails.root.join('log', 'failed_courses_simple.txt')
    
    if File.exist?(simple_log_file)
      File.readlines(simple_log_file).each do |line|
        line = line.strip
        next if line.empty? || line.start_with?('ID|') # Skip header
        
        # Extract ID from new format: "ID|Course Name|State|Website URL|Error Type|Date"
        parts = line.split('|')
        if parts.length >= 6 && parts[0].match?(/^\d+$/)
          failed_course_ids << parts[0].to_i
        end
      end
    end
    
    failed_course_ids
  end
  
  def log_failed_scrape(course_or_array, error_message = nil, error_type = nil)
    # Handle both single course and array of failed courses
    if course_or_array.is_a?(Array)
      failed_courses = course_or_array
    else
      failed_courses = [{
        course: course_or_array,
        error: error_message,
        error_type: error_type
      }]
    end
    
    # Write to detailed log
    log_file = Rails.root.join('log', 'failed_scrapes.log')
    File.open(log_file, 'a') do |f|
      f.puts "\n" + "=" * 80
      f.puts "Failed Scrape Log - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
      f.puts "=" * 80
      
      failed_courses.each do |failed|
        course = failed[:course]
        f.puts "\nCourse: #{course.name}"
        f.puts "ID: #{course.id}"
        f.puts "State: #{course.state&.name || course.state || 'Unknown'}"
        f.puts "Website: #{course.website_url}"
        f.puts "Error Type: #{failed[:error_type]}"
        f.puts "Error: #{failed[:error]}"
        f.puts "Current Data:"
        f.puts "  Phone: #{course.phone.present? ? course.phone : 'MISSING'}"
        f.puts "  Par: #{course.par || 'MISSING'}"
        f.puts "  Holes: #{course.number_of_holes || 'MISSING'}"
        f.puts "  Description: #{course.description.present? ? "#{course.description.length} chars" : 'MISSING'}"
        f.puts "-" * 40
      end
    end
    
    # Write to simple log - CLEAN FORMAT with no dividers
    simple_file = Rails.root.join('log', 'failed_courses_simple.txt')
    
    # Create header if file doesn't exist
    unless File.exist?(simple_file)
      File.open(simple_file, 'w') do |f|
        f.puts "ID|Course Name|State|Website URL|Error Type|Date"
      end
    end
    
    # Append new failed courses - one line per course, no dividers
    File.open(simple_file, 'a') do |f|
      failed_courses.each do |failed|
        course = failed[:course]
        state = course.state&.name || course.state || 'Unknown'
        date = Time.current.strftime('%Y-%m-%d')
        f.puts "#{course.id}|#{course.name}|#{state}|#{course.website_url}|#{failed[:error_type]}|#{date}"
      end
    end
  end
  
  def categorize_error(error_message)
    case error_message
    when /Failed to open TCP connection/, /getaddrinfo/, /nodename nor servname/
      "connection_failed"
    when /Timeout/, /execution expired/
      "timeout"
    when /SSL/, /certificate/
      "ssl_error"
    when /404/, /Not Found/
      "not_found"
    when /403/, /Forbidden/
      "forbidden"
    when /500/, /Internal Server Error/
      "server_error"
    when /redirection forbidden/
      "redirect_error"
    when /invalid byte sequence/
      "encoding_error"
    else
      "unknown_error"
    end
  end
  
  def scrape_course_website(url)
    scraped_data = {}
    
    # Normalize URL
    url = "http://#{url}" unless url.start_with?('http')
    
    # Set timeout and user agent
    options = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      read_timeout: 15
    }
    
    Timeout::timeout(20) do
      doc = Nokogiri::HTML(URI.open(url, options))
      
      # Extract phone numbers
      phone = extract_phone_number(doc)
      scraped_data[:phone] = phone if phone
      
      # Extract email addresses
      email = extract_email(doc)
      scraped_data[:email] = email if email
      
      # Extract enhanced description
      description = extract_enhanced_description(doc)
      scraped_data[:description] = description if description
      
      # Extract course details
      course_details = extract_course_details(doc)
      scraped_data.merge!(course_details) if course_details.any?
      
      # Extract amenities
      amenities = extract_amenities(doc)
      scraped_data[:amenities] = amenities if amenities.any?
      
      # Extract address if missing
      address = extract_address(doc)
      scraped_data[:address] = address if address
    end
    
    scraped_data
  rescue Timeout::Error
    puts "    ⏰ Timeout scraping website"
    {}
  rescue => e
    puts "    ❌ Error: #{e.message}"
    {}
  end
  
  def extract_phone_number(doc)
    # Look for phone numbers in various formats
    phone_patterns = [
      /\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}/,
      /\d{3}[-.\s]\d{3}[-.\s]\d{4}/
    ]
    
    # Search in text content and href attributes
    text_content = doc.text
    phone_links = doc.css('a[href^="tel:"]').map { |a| a['href'].gsub('tel:', '') }
    
    # Try phone links first
    phone_links.each do |phone|
      cleaned = phone.gsub(/[^\d]/, '')
      return format_phone(cleaned) if cleaned.length == 10
    end
    
    # Then search in text
    phone_patterns.each do |pattern|
      match = text_content.match(pattern)
      if match
        cleaned = match[0].gsub(/[^\d]/, '')
        return format_phone(cleaned) if cleaned.length == 10
      end
    end
    
    nil
  end
  
  def extract_email(doc)
    # Look for email addresses
    email_pattern = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
    
    # Search in mailto links first
    mailto_links = doc.css('a[href^="mailto:"]').map { |a| a['href'].gsub('mailto:', '') }
    return mailto_links.first if mailto_links.any?
    
    # Then search in text content
    match = doc.text.match(email_pattern)
    match ? match[0] : nil
  end
  
  def extract_course_details(doc)
    details = {}
    text_content = doc.text.downcase
    
    # Extract number of holes FIRST - we need this for par validation
    holes_patterns = [
      /(\d{1,2})\s*holes?/,
      /(\d{1,2})[-\s]*hole/
    ]
    
    holes_patterns.each do |pattern|
      match = text_content.match(pattern)
      if match
        holes = match[1].to_i
        details[:number_of_holes] = holes if [9, 18, 27, 36].include?(holes)
        break
      end
    end
    
    # Extract yardage
    yardage_patterns = [
      /(\d{4,5})\s*yards?/,
      /yardage[:\s]*(\d{4,5})/,
      /length[:\s]*(\d{4,5})/,
      /(\d{4,5})\s*yard\s*course/
    ]
    
    yardage_patterns.each do |pattern|
      match = text_content.match(pattern)
      if match
        yardage = match[1].to_i
        details[:yardage] = yardage if yardage > 3000 && yardage < 8000
        break
      end
    end
    
    # Extract par - improved with better context detection and hole count validation
    par_patterns = [
      # Look for "course par" or "total par" specifically
      /(?:course|total)\s*par[:\s]*(\d{2})/,
      /par[:\s]*(\d{2})\s*(?:course|total|golf)/,
      
      # Look for par in course description context
      /(?:18|nine|9)\s*hole.*?par[:\s]*(\d{2})/,
      /par[:\s]*(\d{2}).*?(?:18|nine|9)\s*hole/,
      
      # Look for par with yardage context (more reliable)
      /par[:\s]*(\d{2}).*?(\d{4,5})\s*yards?/,
      /(\d{4,5})\s*yards?.*?par[:\s]*(\d{2})/,
      
      # Standard patterns but with better boundaries
      /\bpar[:\s]*(\d{2})\b/,
      /\b(\d{2})\s*par\b/
    ]
    
    par_patterns.each do |pattern|
      match = text_content.match(pattern)
      if match
        # Handle patterns that capture multiple groups
        par_value = match.captures.find { |capture| capture && capture.to_i.between?(27, 80) }
        par = par_value.to_i if par_value
        
        if par && par.between?(27, 80)
          # Additional validation: check if it makes sense with hole count
          if details[:number_of_holes]
            holes = details[:number_of_holes]
            # Validate par makes sense for the number of holes
            if (holes == 9 && par.between?(27, 45)) || 
               (holes == 18 && par.between?(54, 80)) ||
               (holes == 27 && par.between?(81, 120))
              details[:par] = par
              puts "    ✅ Par #{par} validated for #{holes} holes"
              break
            else
              puts "    ❌ Par #{par} rejected for #{holes} holes (doesn't make sense)"
            end
          else
            # No hole count available, use broader validation
            # Allow executive courses (par 54-65), regulation (par 70-72), par-3 courses (par 27-54)
            if par.between?(27, 80)
              details[:par] = par
              puts "    ⚠️ Par #{par} accepted (no hole count to validate against)"
              break
            end
          end
        end
      end
    end
    
    details
  end
  
  def extract_amenities(doc)
    # Use the standardized amenities system
    text_content = doc.text.downcase
    
    # Find amenities using our standardized system
    found_amenities = GolfAmenityProcessor.find_amenities_in_text(text_content)
    
    found_amenities
  end
  
  def extract_enhanced_description(doc)
    # Try multiple sources for better descriptions
    
    # 1. Meta description
    meta_desc = doc.css('meta[name="description"]').first
    if meta_desc && meta_desc['content'] && meta_desc['content'].length > 50
      return clean_text(meta_desc['content'])
    end
    
    # 2. Open Graph description
    og_desc = doc.css('meta[property="og:description"]').first
    if og_desc && og_desc['content'] && og_desc['content'].length > 50
      return clean_text(og_desc['content'])
    end
    
    # 3. Specific golf content selectors
    content_selectors = [
      '.course-description', '.about-course', '.course-overview',
      '.golf-course-description', '.course-info', '.course-details',
      '.description', '.about', '.overview', '.content', '.intro',
      '#description', '#about', '#overview', '#content', '#intro',
      'main p', '.main p', '.hero p', '.banner p',
      '.course-summary', '.golf-summary', '.facility-description'
    ]
    
    content_selectors.each do |selector|
      elements = doc.css(selector)
      elements.each do |element|
        text = clean_text(element.text)
        return text if text.length > 50 && text.length < 800
      end
    end
    
    # 4. Look for the first substantial paragraph
    paragraphs = doc.css('p')
    paragraphs.each do |p|
      text = clean_text(p.text)
      if text.length > 100 && text.length < 600
        # Check if it's golf-related
        golf_keywords = ['golf', 'course', 'hole', 'green', 'fairway', 'tee', 'par', 'yard']
        if golf_keywords.any? { |keyword| text.downcase.include?(keyword) }
          return text
        end
      end
    end
    
    nil
  end
  
  def extract_address(doc)
    # Look for address information
    address_selectors = [
      '.address', '.location', '.contact-info',
      '#address', '#location', '#contact'
    ]
    
    address_selectors.each do |selector|
      element = doc.css(selector).first
      if element
        text = clean_text(element.text)
        return text if text.length > 10 && text.length < 200
      end
    end
    
    nil
  end
  
  def format_phone(phone_digits)
    return nil unless phone_digits.length == 10
    "(#{phone_digits[0..2]}) #{phone_digits[3..5]}-#{phone_digits[6..9]}"
  end
  
  def clean_text(text)
    text.strip.gsub(/\s+/, ' ').gsub(/[^\w\s.,!?-]/, '')
  end
  
  def update_course_with_scraped_data(course, scraped_data)
    updates = {}
    
    # Update fields that exist on the Course model and are missing or default
    updates[:phone] = scraped_data[:phone] if scraped_data[:phone] && course.phone.blank?
    updates[:email] = scraped_data[:email] if scraped_data[:email] && course.email.blank?
    updates[:description] = scraped_data[:description] if scraped_data[:description] && course.description.blank?
    
    # Update course details if missing
    updates[:par] = scraped_data[:par] if scraped_data[:par] && course.par.nil?
    updates[:yardage] = scraped_data[:yardage] if scraped_data[:yardage] && course.yardage.nil?
    updates[:number_of_holes] = scraped_data[:number_of_holes] if scraped_data[:number_of_holes] && course.number_of_holes.nil?
    
    # Update amenities if found - now using standardized system
    if scraped_data[:amenities] && scraped_data[:amenities].any?
      # Convert raw amenities to standardized format
      standardized_amenities = StandardizedAmenityProcessor.standardize_amenities(scraped_data[:amenities])
      
      # Merge with existing amenities, avoiding duplicates
      existing_amenities = course.amenities || []
      new_amenities = (existing_amenities + standardized_amenities).uniq.sort
      updates[:amenities] = new_amenities
    end
    
    if updates.any?
      course.update!(updates)
      puts "    📝 Updated: #{updates.keys.join(', ')}"
      
      # Show standardized amenities that were added
      if updates[:amenities]
        new_standardized = StandardizedAmenityProcessor.standardize_amenities(scraped_data[:amenities])
        categorized = StandardizedAmenityProcessor.categorize_amenities(new_standardized)
        
        puts "    🏌️ Standardized Amenities Added:"
        categorized.each do |category, amenities|
          puts "      #{category}: #{amenities.join(', ')}"
        end
      end
    else
      puts "    ℹ️ No updates needed (existing fields already have data)"
    end
  end
  
  def scrape_course_website_enhanced(url, course_name)
    scraped_data = {}
    
    # Normalize URL
    url = "http://#{url}" unless url.start_with?('http')
    
    # Set timeout and user agent
    options = {
      'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
      read_timeout: 15
    }
    
    Timeout::timeout(20) do
      doc = Nokogiri::HTML(URI.open(url, options))
      
      # Determine course type and scraping strategy
      course_type = determine_course_scraping_strategy(doc, url, course_name)
      puts "    🎯 Detected course type: #{course_type}"
      
      case course_type
      when :premium_booking_system
        scraped_data.merge!(scrape_premium_course(doc, url, course_name))
      when :standard_golf_site
        scraped_data.merge!(scrape_standard_course(doc))
      when :basic_site
        scraped_data.merge!(scrape_basic_course(doc))
      end
      
      # Always try basic extraction as fallback
      scraped_data.merge!(scrape_basic_course(doc)) if scraped_data.empty?
      
      # REMOVED: Tee time link following and booking system detection
    end
    
    scraped_data
  rescue Timeout::Error
    puts "    ⏰ Timeout scraping website"
    {}
  rescue => e
    puts "    ❌ Error: #{e.message}"
    {}
  end
  
  def determine_course_scraping_strategy(doc, url, course_name)
    # Check for premium booking systems
    premium_indicators = [
      'book.teeitup.com', 'book.rguest.com', 'chronogolf.com', 'foretees.com',
      'golfnow.com', 'teetimes.com', 'ezlinks.com', 'lightspeedgolf.com'
    ]
    
    if premium_indicators.any? { |indicator| url.include?(indicator) }
      return :premium_booking_system
    end
    
    # Check for sophisticated golf course sites
    golf_indicators = doc.css('script, div, class').text.downcase
    if golf_indicators.include?('booking') || golf_indicators.include?('tee time') || 
       golf_indicators.include?('reservation') || golf_indicators.include?('rates')
      return :standard_golf_site
    end
    
    :basic_site
  end
  
  def scrape_premium_course(doc, url, course_name)
    data = {}
    
    puts "    🏆 Using premium course scraping strategy"
    
    # For booking system sites, look for course details and amenities
    if url.include?('teeitup.com')
      data.merge!(scrape_teeitup_system(doc))
    elsif url.include?('rguest.com')
      data.merge!(scrape_rguest_system(doc))
    elsif url.include?('tpc.com')
      data.merge!(scrape_tpc_system(doc))
    end
    
    # REMOVED: Booking URL and pricing notes extraction
    
    data
  end
  
  def scrape_teeitup_system(doc)
    data = {}
    
    # REMOVED: TeeItUp pricing extraction
    
    # Look for course details in TeeItUp format
    if course_info = doc.css('.course-info, .course-details').first
      info_text = course_info.text.downcase
      
      # Extract yardage
      if match = info_text.match(/(\d{4,5})\s*yards?/)
        data[:yardage] = match[1].to_i
      end
      
      # Extract par
      if match = info_text.match(/par[:\s]*(\d{2})/)
        data[:par] = match[1].to_i
      end
    end
    
    data
  end
  
  def scrape_rguest_system(doc)
    data = {}
    
    # REMOVED: RGuest pricing extraction
    
    data
  end
  
  def scrape_tpc_system(doc)
    data = {}
    
    # REMOVED: TPC pricing extraction
    
    data
  end
  
  def scrape_standard_course(doc)
    data = {}
    
    puts "    🏌️ Using standard golf course scraping strategy"
    
    # Use enhanced extraction methods (excluding green fees)
    phone = extract_phone_number(doc)
    data[:phone] = phone if phone
    
    email = extract_email(doc)
    data[:email] = email if email
    
    description = extract_enhanced_description(doc)
    data[:description] = description if description
    
    course_details = extract_course_details(doc)
    data.merge!(course_details) if course_details.any?
    
    amenities = extract_amenities(doc)
    data[:amenities] = amenities if amenities.any?
    
    data
  end
  
  def scrape_basic_course(doc)
    data = {}
    
    puts "    📄 Using basic site scraping strategy"
    
    # Basic extraction for simple sites (excluding green fees)
    phone = extract_phone_number(doc)
    data[:phone] = phone if phone
    
    email = extract_email(doc)
    data[:email] = email if email
    
    # Basic description
    meta_desc = doc.css('meta[name="description"]').first
    if meta_desc && meta_desc['content'] && meta_desc['content'].length > 30
      data[:description] = clean_text(meta_desc['content'])
    end
    
    data
  end
end 