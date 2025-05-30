class TagEmojiService
  TAG_EMOJIS = {
    # Golf Experience & Prestige
    'golf:top100' => '🏆',
    'golf:bucket_list' => '🎯',
    'golf:championship' => '🏆',
    'golf:pga_tour' => '⛳',
    'golf:major_championship' => '🥇',
    
    # Course Style & Design
    'golf:links' => '🌊',
    'golf:parkland' => '🌳',
    'golf:desert' => '🏜️',
    'golf:mountain' => '⛰️',
    'golf:resort' => '🏨',
    'golf:historic' => '🏛️',
    
    # Layout Features
    'layout:water_hazards' => '💧',
    'layout:elevation_changes' => '📈',
    'layout:tree_lined' => '🌲',
    'layout:island_greens' => '🏝️',
    'layout:bunkers' => '🏖️',
    'layout:doglegs' => '🐕',
    'layout:narrow_fairways' => '🎯',
    'layout:wide_fairways' => '🛣️',
    
    # Difficulty & Playability
    'play:walkable' => '🚶',
    'play:cart_required' => '🛺',
    'play:beginner_friendly' => '🔰',
    'play:challenging' => '💪',
    'play:well_maintained' => '✨',
    
    # Trip & Experience Type
    'trip:luxury' => '💎',
    'trip:pure_golf' => '⛳',
    'trip:buddies' => '👥',
    'trip:weekend' => '📅',
    'trip:group_friendly' => '👨‍👩‍👧‍👦',
    'trip:remote' => '🗺️',
    
    # Legacy golf course tags (for backward compatibility)
    'golf:top_100_courses' => '🏆',
    'golf:bucket_list' => '🎯',
    'golf:links' => '🌊',
    'golf:parkland' => '🌳',
    'golf:desert' => '🏜️',
    'golf:mountain' => '⛰️',
    'golf:resort' => '⛳',
    
    # Golf Facilities
    'amenity:driving_range' => '🏌️',
    'amenity:putting_green' => '⛳',
    'amenity:short_game_area' => '🎯',
    'amenity:practice_facility' => '🏌️‍♂️',
    
    # Pro Shop & Services
    'amenity:pro_shop' => '🛍️',
    'amenity:club_rentals' => '🏌️‍♀️',
    'amenity:golf_lessons' => '👨‍🏫',
    'amenity:golf_carts' => '🛺',
    
    # Dining & Social
    'amenity:restaurant' => '🍽️',
    'amenity:bar' => '🍺',
    'amenity:snack_bar' => '🥪',
    'amenity:beverage_cart' => '🚐',
    
    # Facilities
    'amenity:clubhouse' => '🏛️',
    'amenity:locker_rooms' => '🚿',
    'amenity:spa' => '💆',
    'amenity:fitness_center' => '💪',
    
    # Events & Accommodation
    'amenity:lodging' => '🏨',
    'amenity:onsite_lodging' => '🏨',
    'amenity:event_space' => '🎪',
    'amenity:tournament_host' => '🏆',
    'amenity:wedding_venue' => '💒',
    'amenity:conference_facilities' => '🏢',
    'amenity:banquet_facilities' => '🍽️',
    
    # Premium Services
    'amenity:caddies_available' => '👨‍💼',
    'amenity:caddie_service' => '👨‍💼',
    'amenity:bag_drop_service' => '🎒',
    'amenity:multiple_courses' => '⛳',
    'amenity:nightlife' => '🌃',
    
    # Course Features
    'amenity:desert_course' => '🏜️',
    'amenity:water_features' => '💧',
    'amenity:walking_only' => '🚶',
    'amenity:cart_path_only' => '🛤️'
  }.freeze

  def self.emoji_for(tag)
    # Handle both prefixed and non-prefixed tags
    emoji = TAG_EMOJIS[tag]
    
    # If no direct match, try with golf: prefix for backward compatibility
    if emoji.nil? && !tag.start_with?('golf:', 'layout:', 'play:', 'trip:', 'amenity:')
      emoji = TAG_EMOJIS["golf:#{tag}"]
    end
    
    emoji || '🏷️'
  end
end 