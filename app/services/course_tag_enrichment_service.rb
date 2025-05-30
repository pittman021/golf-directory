class CourseTagEnrichmentService
  def initialize(course)
    @course = course
    @suggested_tags = []
  end

  def enrich_tags
    analyze_course_characteristics
    apply_suggested_tags
    @suggested_tags
  end

  private

  def analyze_course_characteristics
    analyze_name_and_description
    analyze_location_and_geography
    analyze_course_specs
    analyze_amenities
    analyze_pricing
    analyze_website_content
  end

  def analyze_name_and_description
    text = "#{@course.name} #{@course.description}".downcase
    
    # Golf Experience & Prestige
    suggest_tag('golf:championship') if text.match?(/championship|tournament|pga|lpga|major/)
    suggest_tag('golf:historic') if text.match?(/historic|heritage|classic|traditional|founded|established.*19[0-4]/)
    suggest_tag('golf:bucket_list') if text.match?(/bucket list|must play|world.?class|legendary|iconic/)
    
    # Course Style & Design
    suggest_tag('golf:links') if text.match?(/links|seaside|coastal|ocean|dunes|wind/)
    suggest_tag('golf:parkland') if text.match?(/parkland|tree.?lined|wooded|forest/)
    suggest_tag('golf:desert') if text.match?(/desert|arizona|nevada|palm springs|scottsdale/)
    suggest_tag('golf:mountain') if text.match?(/mountain|alpine|elevation|valley|ridge|peak/)
    suggest_tag('golf:resort') if text.match?(/resort|spa|hotel|lodge|accommodation/)
    
    # Layout Features
    suggest_tag('layout:water_hazards') if text.match?(/water|lake|pond|creek|river|stream|hazard/)
    suggest_tag('layout:island_greens') if text.match?(/island green|island hole/)
    suggest_tag('layout:elevation_changes') if text.match?(/elevation|hill|slope|valley|mountain/)
    suggest_tag('layout:tree_lined') if text.match?(/tree.?lined|wooded|forest|oak|pine/)
    
    # Trip Types
    suggest_tag('trip:luxury') if text.match?(/luxury|premium|exclusive|private|upscale|five.?star/)
    suggest_tag('trip:pure_golf') if text.match?(/pure golf|golf purist|traditional golf|classic golf/)
    suggest_tag('trip:remote') if text.match?(/remote|secluded|hidden|off.?beaten|destination/)
  end

  def analyze_location_and_geography
    return unless @course.state

    state_name = @course.state.name.downcase
    
    # Desert states
    desert_states = ['arizona', 'nevada', 'new mexico', 'utah']
    suggest_tag('golf:desert') if desert_states.include?(state_name)
    
    # Mountain states
    mountain_states = ['colorado', 'montana', 'wyoming', 'idaho', 'utah', 'new mexico']
    suggest_tag('golf:mountain') if mountain_states.include?(state_name)
    
    # Coastal states - links potential
    coastal_states = ['california', 'oregon', 'washington', 'florida', 'south carolina', 'north carolina', 'maine', 'massachusetts', 'new york', 'new jersey']
    if coastal_states.include?(state_name) && @course.name.downcase.match?(/beach|ocean|bay|coast|shore/)
      suggest_tag('golf:links')
    end
    
    # Resort destinations
    resort_states = ['hawaii', 'florida', 'california', 'arizona', 'south carolina']
    if resort_states.include?(state_name) && @course.amenities&.include?('Lodging')
      suggest_tag('golf:resort')
      suggest_tag('trip:luxury')
    end
  end

  def analyze_course_specs
    # Difficulty based on par and yardage
    if @course.par && @course.yardage
      if @course.par >= 72 && @course.yardage >= 7000
        suggest_tag('play:challenging')
      elsif @course.par <= 70 && @course.yardage <= 6000
        suggest_tag('play:beginner_friendly')
      end
    end
    
    # Course length suggests walkability
    if @course.yardage && @course.yardage <= 6200
      suggest_tag('play:walkable')
    elsif @course.yardage && @course.yardage >= 7200
      suggest_tag('play:cart_required')
    end
    
    # 9-hole courses are often beginner friendly
    if @course.number_of_holes == 9
      suggest_tag('play:beginner_friendly')
    end
  end

  def analyze_amenities
    return unless @course.amenities&.any?
    
    amenities = @course.amenities.map(&:downcase)
    
    # Lodging indicates resort
    if amenities.include?('lodging') || amenities.include?('on-site lodging')
      suggest_tag('golf:resort')
      suggest_tag('amenity:onsite_lodging')
    end
    
    # Multiple courses
    if amenities.include?('multiple courses')
      suggest_tag('amenity:multiple_courses')
      suggest_tag('trip:group_friendly')
    end
    
    # Luxury amenities
    luxury_amenities = ['spa', 'fine dining', 'concierge', 'valet', 'caddie service']
    if luxury_amenities.any? { |luxury| amenities.any? { |a| a.include?(luxury) } }
      suggest_tag('trip:luxury')
    end
    
    # Caddie service
    if amenities.any? { |a| a.include?('caddie') }
      suggest_tag('amenity:caddie_service')
      suggest_tag('trip:pure_golf')
    end
    
    # Group facilities
    group_amenities = ['banquet', 'event space', 'tournament', 'group']
    if group_amenities.any? { |group| amenities.any? { |a| a.include?(group) } }
      suggest_tag('trip:group_friendly')
    end
    
    # Nightlife
    nightlife_amenities = ['bar', 'restaurant', 'nightclub', 'entertainment']
    if nightlife_amenities.any? { |night| amenities.any? { |a| a.include?(night) } }
      suggest_tag('amenity:nightlife')
    end
  end

  def analyze_pricing
    return unless @course.green_fee
    
    # High-end pricing suggests luxury
    if @course.green_fee >= 200
      suggest_tag('trip:luxury')
    elsif @course.green_fee >= 150
      suggest_tag('trip:pure_golf') # Premium but focused on golf
    elsif @course.green_fee <= 50
      suggest_tag('play:beginner_friendly')
      suggest_tag('trip:buddies')
    end
  end

  def analyze_website_content
    return unless @course.website_url.present? && !@course.website_url.include?('Pending')
    
    # Check for specific course management companies that indicate quality
    url = @course.website_url.downcase
    
    # TPC courses
    if url.include?('tpc.com') || @course.name.downcase.include?('tpc')
      suggest_tag('golf:championship')
      suggest_tag('golf:pga_tour')
      suggest_tag('trip:pure_golf')
    end
    
    # Troon managed courses
    if url.include?('troon.com')
      suggest_tag('trip:luxury')
      suggest_tag('play:well_maintained')
    end
    
    # ClubCorp courses
    if url.include?('clubcorp.com')
      suggest_tag('trip:luxury')
      suggest_tag('amenity:multiple_courses')
    end
  end

  def suggest_tag(tag)
    @suggested_tags << tag unless @suggested_tags.include?(tag)
  end

  def apply_suggested_tags
    return if @suggested_tags.empty?
    
    # Get current tags
    current_tags = @course.course_tags || []
    
    # Add new tags that aren't already present
    new_tags = @suggested_tags - current_tags
    
    if new_tags.any?
      updated_tags = (current_tags + new_tags).uniq.sort
      @course.update!(course_tags: updated_tags)
      
      Rails.logger.info "CourseTagEnrichmentService: Added tags #{new_tags.join(', ')} to course #{@course.name}"
    end
  end
end 