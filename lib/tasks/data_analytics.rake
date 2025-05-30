namespace :analytics do
  desc "Comprehensive data collection analytics and progress tracking"
  task comprehensive_report: :environment do
    puts "🏌️ Golf Directory Data Analytics Report"
    puts "=" * 80
    puts "Generated: #{Time.current.strftime('%B %d, %Y at %I:%M %p')}"
    puts "=" * 80

    # Overall Statistics
    total_courses = Course.count
    total_locations = Location.count
    total_states = State.count
    
    puts "\n📊 OVERALL DATABASE STATISTICS"
    puts "-" * 50
    puts "Total Courses: #{total_courses.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "Total Locations: #{total_locations}"
    puts "Total States: #{total_states}"
    puts "Average Courses per State: #{(total_courses.to_f / total_states).round(1)}"
    
    # Data Quality Analysis
    puts "\n🎯 DATA QUALITY METRICS"
    puts "-" * 50
    
    # Basic Information Coverage
    courses_with_description = Course.where("description IS NOT NULL AND LENGTH(description) > 50").count
    courses_with_good_notes = Course.where("notes IS NOT NULL AND LENGTH(notes) > 25").count
    courses_with_images = Course.where("image_url IS NOT NULL AND image_url != ''").count
    courses_with_websites = Course.where("website_url IS NOT NULL AND website_url != '' AND website_url NOT LIKE '%Pending%'").count
    courses_with_phone = Course.where("phone IS NOT NULL AND phone != ''").count
    courses_with_email = Course.where("email IS NOT NULL AND email != ''").count
    
    puts "Rich Descriptions (>50 chars): #{courses_with_description} (#{percentage(courses_with_description, total_courses)}%)"
    puts "Good Notes (>25 chars): #{courses_with_good_notes} (#{percentage(courses_with_good_notes, total_courses)}%)"
    puts "Images: #{courses_with_images} (#{percentage(courses_with_images, total_courses)}%)"
    puts "Websites: #{courses_with_websites} (#{percentage(courses_with_websites, total_courses)}%)"
    puts "Phone Numbers: #{courses_with_phone} (#{percentage(courses_with_phone, total_courses)}%)"
    puts "Email Addresses: #{courses_with_email} (#{percentage(courses_with_email, total_courses)}%)"
    
    # Course Details Coverage
    puts "\n🏌️ COURSE DETAILS COVERAGE"
    puts "-" * 50
    
    courses_with_amenities = Course.where.not("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL").count
    courses_with_google_data = Course.where("google_place_id IS NOT NULL AND google_place_id != ''").count
    courses_with_ratings = Course.where("google_rating IS NOT NULL").count
    courses_with_reviews_count = Course.where("google_reviews_count IS NOT NULL AND google_reviews_count > 0").count
    
    puts "Amenities Listed: #{courses_with_amenities} (#{percentage(courses_with_amenities, total_courses)}%)"
    puts "Google Place IDs: #{courses_with_google_data} (#{percentage(courses_with_google_data, total_courses)}%)"
    puts "Google Ratings: #{courses_with_ratings} (#{percentage(courses_with_ratings, total_courses)}%)"
    puts "Google Review Counts: #{courses_with_reviews_count} (#{percentage(courses_with_reviews_count, total_courses)}%)"
    
    # Data Sources Analysis
    puts "\n📡 DATA SOURCES BREAKDOWN"
    puts "-" * 50
    
    google_imported = Course.where("notes LIKE ?", "%Google Places API%").count
    manually_added = total_courses - google_imported
    
    puts "Google Places API: #{google_imported} (#{percentage(google_imported, total_courses)}%)"
    puts "Other Sources: #{manually_added} (#{percentage(manually_added, total_courses)}%)"
    
    # Time-based Analysis
    puts "\n📅 DATA COLLECTION TIMELINE"
    puts "-" * 50
    
    courses_by_month = Course.group("DATE_TRUNC('month', created_at)").count.sort
    puts "Course additions by month:"
    courses_by_month.each do |month, count|
      puts "  #{month.strftime('%B %Y')}: #{count} courses"
    end
    
    # Recent Activity (last 30 days)
    recent_courses = Course.where("created_at > ?", 30.days.ago).count
    recent_updates = Course.where("updated_at > ? AND updated_at != created_at", 30.days.ago).count
    
    puts "\nRecent Activity (last 30 days):"
    puts "  New Courses Added: #{recent_courses}"
    puts "  Courses Updated: #{recent_updates}"
    
    # State Coverage Analysis
    puts "\n🗺️ STATE COVERAGE ANALYSIS"
    puts "-" * 50
    
    state_stats = Course.joins(:state)
                       .group('states.name')
                       .select('states.name, COUNT(*) as course_count')
                       .order('course_count DESC')
    
    puts "Top 10 States by Course Count:"
    state_stats.limit(10).each_with_index do |stat, index|
      puts "  #{index + 1}. #{stat.name}: #{stat.course_count} courses"
    end
    
    puts "\nStates needing attention (< 50 courses):"
    low_coverage_states = state_stats.select { |s| s.course_count < 50 }
    low_coverage_states.each do |stat|
      puts "  #{stat.name}: #{stat.course_count} courses"
    end
    
    # Data Completeness Score
    puts "\n🎯 DATA COMPLETENESS SCORE"
    puts "-" * 50
    
    # Calculate weighted completeness score
    description_score = (courses_with_description.to_f / total_courses) * 15
    image_score = (courses_with_images.to_f / total_courses) * 15
    website_score = (courses_with_websites.to_f / total_courses) * 20
    contact_score = ((courses_with_phone + courses_with_email).to_f / (total_courses * 2)) * 15
    amenities_score = (courses_with_amenities.to_f / total_courses) * 15
    google_score = (courses_with_google_data.to_f / total_courses) * 20
    
    total_score = description_score + image_score + website_score + contact_score + amenities_score + google_score
    
    puts "Overall Data Completeness: #{total_score.round(1)}/100"
    puts "  Descriptions (15%): #{description_score.round(1)}"
    puts "  Images (15%): #{image_score.round(1)}"
    puts "  Websites (20%): #{website_score.round(1)}"
    puts "  Contact Info (15%): #{contact_score.round(1)}"
    puts "  Amenities (15%): #{amenities_score.round(1)}"
    puts "  Google Integration (20%): #{google_score.round(1)}"
    
    # Recommendations
    puts "\n💡 RECOMMENDATIONS"
    puts "-" * 50
    
    if website_score < 15
      puts "🔴 PRIORITY: Website data collection (#{courses_with_websites}/#{total_courses} courses have websites)"
    end
    
    if google_score < 15
      puts "🔴 PRIORITY: Google Places integration (#{courses_with_google_data}/#{total_courses} courses have Place IDs)"
    end
    
    if amenities_score < 10
      puts "🟡 MEDIUM: Amenities data collection (#{courses_with_amenities}/#{total_courses} courses have amenities)"
    end
    
    if description_score < 10
      puts "🟡 MEDIUM: Course descriptions (#{courses_with_description}/#{total_courses} courses have good descriptions)"
    end
    
    if contact_score < 10
      puts "🟡 MEDIUM: Contact information (Phone: #{courses_with_phone}, Email: #{courses_with_email})"
    end
    
    # Next Steps
    puts "\n🚀 SUGGESTED NEXT STEPS"
    puts "-" * 50
    puts "1. Run 'rails courses:scrape_all_remaining_courses' to get website data"
    puts "2. Run 'rails courses:enrich_sparse' to fill missing Google data"
    puts "3. Focus on states with < 50 courses for discovery"
    puts "4. Implement automated data quality monitoring"
    
    # Export summary to file
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    summary_file = Rails.root.join('tmp', "analytics_summary_#{timestamp}.txt")
    
    File.open(summary_file, 'w') do |file|
      file.puts "Golf Directory Analytics Summary - #{Time.current.strftime('%B %d, %Y')}"
      file.puts "=" * 60
      file.puts "Total Courses: #{total_courses}"
      file.puts "Data Completeness Score: #{total_score.round(1)}/100"
      file.puts "Courses with Websites: #{courses_with_websites} (#{percentage(courses_with_websites, total_courses)}%)"
      file.puts "Courses with Google Data: #{courses_with_google_data} (#{percentage(courses_with_google_data, total_courses)}%)"
      file.puts "Recent Additions (30 days): #{recent_courses}"
      file.puts "States needing attention: #{low_coverage_states.count}"
    end
    
    puts "\n📄 Summary exported to: #{summary_file}"
    puts "\n" + "=" * 80
  end
  
  desc "Track data collection progress over time"
  task progress_tracking: :environment do
    puts "📈 Data Collection Progress Tracking"
    puts "=" * 60
    
    # Create or update progress tracking
    today = Date.current
    
    # Calculate current metrics
    total_courses = Course.count
    courses_with_websites = Course.where("website_url IS NOT NULL AND website_url != '' AND website_url NOT LIKE '%Pending%'").count
    courses_with_google_data = Course.where("google_place_id IS NOT NULL").count
    courses_with_amenities = Course.where.not("amenities IS NULL OR ARRAY_LENGTH(amenities, 1) IS NULL").count
    courses_with_descriptions = Course.where("description IS NOT NULL AND LENGTH(description) > 50").count
    
    # Store in a simple tracking file
    tracking_file = Rails.root.join('tmp', 'progress_tracking.csv')
    
    # Create header if file doesn't exist
    unless File.exist?(tracking_file)
      File.open(tracking_file, 'w') do |file|
        file.puts "date,total_courses,courses_with_websites,courses_with_google_data,courses_with_amenities,courses_with_descriptions,website_percentage,google_percentage,amenities_percentage,descriptions_percentage"
      end
    end
    
    # Append today's data
    File.open(tracking_file, 'a') do |file|
      file.puts "#{today},#{total_courses},#{courses_with_websites},#{courses_with_google_data},#{courses_with_amenities},#{courses_with_descriptions},#{percentage(courses_with_websites, total_courses)},#{percentage(courses_with_google_data, total_courses)},#{percentage(courses_with_amenities, total_courses)},#{percentage(courses_with_descriptions, total_courses)}"
    end
    
    puts "✅ Progress data recorded for #{today}"
    puts "📊 Current metrics:"
    puts "  Total Courses: #{total_courses}"
    puts "  Websites: #{courses_with_websites} (#{percentage(courses_with_websites, total_courses)}%)"
    puts "  Google Data: #{courses_with_google_data} (#{percentage(courses_with_google_data, total_courses)}%)"
    puts "  Amenities: #{courses_with_amenities} (#{percentage(courses_with_amenities, total_courses)}%)"
    puts "  Descriptions: #{courses_with_descriptions} (#{percentage(courses_with_descriptions, total_courses)}%)"
    
    # Show progress if we have historical data
    if File.exist?(tracking_file)
      lines = File.readlines(tracking_file)
      if lines.length > 2 # Header + at least 2 data points
        puts "\n📈 Progress since last tracking:"
        previous_line = lines[-2].strip.split(',')
        current_line = lines[-1].strip.split(',')
        
        prev_total = previous_line[1].to_i
        curr_total = current_line[1].to_i
        
        puts "  Courses added: #{curr_total - prev_total}"
        puts "  Website coverage change: #{current_line[6].to_f - previous_line[6].to_f}%"
        puts "  Google data coverage change: #{current_line[7].to_f - previous_line[7].to_f}%"
      end
    end
    
    puts "\n📄 Tracking data saved to: #{tracking_file}"
  end
  
  desc "Generate weekly data quality report"
  task weekly_report: :environment do
    puts "📅 Weekly Data Quality Report"
    puts "=" * 50
    puts "Week ending: #{Date.current.strftime('%B %d, %Y')}"
    
    # Courses added this week
    week_start = 1.week.ago
    new_courses = Course.where("created_at > ?", week_start).count
    updated_courses = Course.where("updated_at > ? AND updated_at != created_at", week_start).count
    
    puts "\n📊 This Week's Activity:"
    puts "  New courses added: #{new_courses}"
    puts "  Courses updated: #{updated_courses}"
    
    # Data quality improvements
    recent_websites = Course.where("updated_at > ? AND website_url IS NOT NULL AND website_url != ''", week_start).count
    recent_amenities = Course.where("updated_at > ? AND amenities IS NOT NULL", week_start).count
    
    puts "\n🎯 Data Quality Improvements:"
    puts "  Websites added: #{recent_websites}"
    puts "  Amenities added: #{recent_amenities}"
    
    # Top states for new additions
    puts "\n🗺️ Top States for New Courses:"
    new_by_state = Course.joins(:state)
                        .where("courses.created_at > ?", week_start)
                        .group('states.name')
                        .count
                        .sort_by { |_, count| -count }
                        .first(5)
    
    new_by_state.each do |state, count|
      puts "  #{state}: #{count} new courses"
    end
    
    puts "\n💡 Focus Areas for Next Week:"
    
    # Identify areas needing attention
    total_courses = Course.count
    website_coverage = Course.where("website_url IS NOT NULL AND website_url != ''").count
    
    if (website_coverage.to_f / total_courses) < 0.5
      puts "  🔴 Priority: Website data collection (#{percentage(website_coverage, total_courses)}% coverage)"
    end
    
    sparse_courses = Course.where("(description IS NULL OR LENGTH(description) < 50) AND google_place_id IS NOT NULL").count
    if sparse_courses > 1000
      puts "  🟡 Medium: Enrich #{sparse_courses} courses with Google Place IDs"
    end
    
    puts "\n📧 Report generated: #{Time.current.strftime('%I:%M %p')}"
  end
  
  private
  
  def percentage(part, total)
    return 0 if total.zero?
    ((part.to_f / total) * 100).round(1)
  end
end 