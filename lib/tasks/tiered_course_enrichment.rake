namespace :courses do
  desc "Implement tiered enrichment system for courses based on quality/importance"
  task setup_tiers: :environment do
    puts "🏆 Setting up course tiers for targeted enrichment..."
    
    # Define course tiers
    TIER_1_PREMIUM = "premium"     # Top 100, famous courses - full enrichment
    TIER_2_NOTABLE = "notable"     # Good private/resort courses - moderate enrichment  
    TIER_3_STANDARD = "standard"   # Public/municipal courses - basic enrichment
    TIER_4_MINIMAL = "minimal"     # Basic courses - name/location only
    
    total_courses = Course.count
    puts "Total courses to categorize: #{total_courses}"
    
    tier_1_count = 0
    tier_2_count = 0
    tier_3_count = 0
    tier_4_count = 0
    
    Course.find_each.with_index do |course, index|
      print "\rCategorizing course #{index + 1}/#{total_courses}: #{course.name[0..30]}..." if (index + 1) % 100 == 0
      
      tier = determine_course_tier(course)
      
      # Add tier to course_tags if not already present
      unless course.course_tags.include?(tier)
        course.course_tags = (course.course_tags + [tier]).uniq
        course.save!
      end
      
      case tier
      when TIER_1_PREMIUM
        tier_1_count += 1
      when TIER_2_NOTABLE
        tier_2_count += 1
      when TIER_3_STANDARD
        tier_3_count += 1
      when TIER_4_MINIMAL
        tier_4_count += 1
      end
    end
    
    puts "\n\n📊 Course Tier Distribution:"
    puts "=" * 50
    puts "Tier 1 (Premium): #{tier_1_count} courses (#{(tier_1_count.to_f / total_courses * 100).round(1)}%)"
    puts "  - Top 100 courses, famous venues, major championship sites"
    puts "  - Full enrichment: detailed descriptions, photos, amenities, history"
    puts
    puts "Tier 2 (Notable): #{tier_2_count} courses (#{(tier_2_count.to_f / total_courses * 100).round(1)}%)"
    puts "  - Quality private clubs, resort courses, regional favorites"
    puts "  - Moderate enrichment: good descriptions, basic amenities"
    puts
    puts "Tier 3 (Standard): #{tier_3_count} courses (#{(tier_3_count.to_f / total_courses * 100).round(1)}%)"
    puts "  - Public courses, municipal courses, daily fee courses"
    puts "  - Basic enrichment: short description, contact info, basic details"
    puts
    puts "Tier 4 (Minimal): #{tier_4_count} courses (#{(tier_4_count.to_f / total_courses * 100).round(1)}%)"
    puts "  - Basic courses, driving ranges, par-3 courses"
    puts "  - Minimal enrichment: name, location, contact only"
    puts
  end
  
  desc "Enrich courses using tiered approach"
  task enrich_tiered: :environment do
    puts "🎯 Starting tiered course enrichment..."
    
    # Process each tier with different enrichment levels
    tiers_to_process = [
      { name: "premium", limit: 10, full_enrichment: true },
      { name: "notable", limit: 15, full_enrichment: false },
      { name: "standard", limit: 20, full_enrichment: false },
      { name: "minimal", limit: 25, full_enrichment: false }
    ]
    
    total_enriched = 0
    
    tiers_to_process.each do |tier_config|
      puts "\n🔄 Processing #{tier_config[:name].upcase} tier courses..."
      
      # Find courses in this tier that need enrichment
      courses_to_enrich = Course.where("'#{tier_config[:name]}' = ANY(course_tags)")
                               .where.not(google_place_id: nil)
                               .where("(description IS NULL OR LENGTH(description) < 50) OR 
                                       (notes IS NULL OR LENGTH(notes) < 25) OR 
                                       (image_url IS NULL OR image_url = '') OR
                                       (website_url IS NULL OR website_url = '')")
                               .limit(tier_config[:limit])
      
      puts "Found #{courses_to_enrich.count} #{tier_config[:name]} courses to enrich"
      
      courses_to_enrich.find_each.with_index do |course, index|
        puts "\n  #{index + 1}/#{courses_to_enrich.count}: Enriching #{course.name}..."
        
        begin
          if tier_config[:full_enrichment]
            # Full enrichment for premium courses
            enrich_premium_course(course)
          else
            # Basic enrichment for other tiers
            enrich_basic_course(course, tier_config[:name])
          end
          
          total_enriched += 1
          puts "  ✅ Successfully enriched #{course.name}"
          
          # Respect API rate limits
          sleep_time = tier_config[:full_enrichment] ? 5 : 2
          sleep(sleep_time)
          
        rescue StandardError => e
          puts "  ❌ Error enriching #{course.name}: #{e.message}"
        end
      end
    end
    
    puts "\n📊 Tiered Enrichment Summary:"
    puts "Total courses enriched: #{total_enriched}"
    puts "\n💡 Run again to continue enriching more courses in each tier."
  end
  
  desc "Show tier statistics and recommendations"
  task tier_stats: :environment do
    puts "📈 Course Tier Statistics"
    puts "=" * 50
    
    %w[premium notable standard minimal].each do |tier|
      courses_in_tier = Course.where("'#{tier}' = ANY(course_tags)")
      total_count = courses_in_tier.count
      
      # Count courses that need enrichment
      need_enrichment = courses_in_tier.where("(description IS NULL OR LENGTH(description) < 50) OR 
                                               (notes IS NULL OR LENGTH(notes) < 25) OR 
                                               (image_url IS NULL OR image_url = '') OR
                                               (website_url IS NULL OR website_url = '')")
      
      # Count courses with Google Place IDs
      with_place_ids = need_enrichment.where.not(google_place_id: nil)
      
      puts "\n#{tier.upcase} Tier:"
      puts "  Total courses: #{total_count}"
      puts "  Need enrichment: #{need_enrichment.count} (#{(need_enrichment.count.to_f / total_count * 100).round(1)}%)"
      puts "  Ready to enrich (have Place ID): #{with_place_ids.count}"
      
      # Show some examples
      if total_count > 0
        puts "  Examples:"
        courses_in_tier.limit(3).each do |course|
          puts "    - #{course.name} (#{course.state || 'Unknown state'})"
        end
      end
    end
    
    puts "\n🎯 Enrichment Priority Recommendations:"
    puts "1. Start with Premium tier (highest value courses)"
    puts "2. Focus on courses with Google Place IDs"
    puts "3. Process in small batches to manage API costs"
    puts "4. Use different enrichment levels per tier"
  end
  
  private
  
  def determine_course_tier(course)
    course_name = course.name.downcase
    course_tags = course.course_tags.map(&:downcase)
    
    # Tier 1: Premium courses
    return "premium" if course_tags.include?("top_100")
    return "premium" if course_name.include?("country club") && (course_name.include?("national") || course_name.include?("golf club"))
    return "premium" if course_name.match?(/\b(augusta|pebble beach|pinehurst|bethpage|torrey pines|whistling straits)\b/)
    return "premium" if course_tags.any? { |tag| %w[championship major pga tour].include?(tag) }
    return "premium" if course.green_fee.to_i > 300 # High-end courses
    
    # Tier 2: Notable courses  
    return "notable" if course_name.include?("country club") || course_name.include?("golf club")
    return "notable" if course_name.include?("resort") || course_name.include?("lodge")
    return "notable" if course.green_fee.to_i > 150 && course.green_fee.to_i <= 300
    return "notable" if course_tags.any? { |tag| %w[private resort upscale].include?(tag) }
    
    # Tier 3: Standard courses
    return "standard" if course_name.include?("golf course") || course_name.include?("golf links")
    return "standard" if course_name.include?("municipal") || course_name.include?("public")
    return "standard" if course.green_fee.to_i > 50 && course.green_fee.to_i <= 150
    return "standard" if course_tags.any? { |tag| %w[public municipal daily_fee].include?(tag) }
    
    # Tier 4: Minimal courses (everything else)
    "minimal"
  end
  
  def enrich_premium_course(course)
    puts "    🏆 Full enrichment for premium course..."
    
    # Use the full GetCourseInfoService for premium courses
    service = GetCourseInfoService.new(course)
    service.gather_info
    
    # Additional premium enrichment could go here
    # - Historical information
    # - Championship history
    # - Architect information
    # - Multiple photos
  end
  
  def enrich_basic_course(course, tier)
    puts "    📝 Basic enrichment for #{tier} course..."
    
    # For non-premium courses, we'll use a lighter approach
    # This could be a simplified version of GetCourseInfoService
    # or just basic Google Places data
    
    if course.google_place_id.present?
      # Get basic info from Google Places
      # This would be a lighter API call than the full enrichment
      service = GetCourseInfoService.new(course)
      
      # We could modify the service to have a "basic_mode" that skips
      # expensive operations like detailed descriptions
      service.gather_info
    end
  end
end 