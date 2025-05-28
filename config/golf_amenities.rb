# Golf Course Amenities Configuration
# Standardized amenities for golf courses organized by category

GOLF_AMENITIES = {
  # Golf Facilities
  golf_facilities: {
    'driving_range' => {
      keywords: ['driving range', 'practice range', 'range'],
      icon: '🏌️',
      description: 'Driving range for practice'
    },
    'putting_green' => {
      keywords: ['putting green', 'practice green', 'putting'],
      icon: '⛳',
      description: 'Practice putting green'
    },
    'chipping_green' => {
      keywords: ['chipping green', 'chipping area', 'short game'],
      icon: '🎯',
      description: 'Chipping and short game practice area'
    },
    'practice_facility' => {
      keywords: ['practice facility', 'practice area', 'learning center'],
      icon: '🏌️‍♂️',
      description: 'Comprehensive practice facility'
    }
  },

  # Dining & Entertainment
  dining: {
    'restaurant' => {
      keywords: ['restaurant', 'dining', 'grill', 'bar and grill', 'steakhouse'],
      icon: '🍽️',
      description: 'Full-service restaurant'
    },
    'bar' => {
      keywords: ['bar', 'lounge', 'tavern', 'pub'],
      icon: '🍺',
      description: 'Bar or lounge'
    },
    'snack_bar' => {
      keywords: ['snack bar', 'grill', 'quick service', 'concessions'],
      icon: '🥪',
      description: 'Snack bar or quick service'
    },
    'banquet_facilities' => {
      keywords: ['banquet', 'event space', 'private dining', 'ballroom'],
      icon: '🎉',
      description: 'Banquet and event facilities'
    }
  },

  # Pro Shop & Services
  pro_shop: {
    'pro_shop' => {
      keywords: ['pro shop', 'golf shop', 'merchandise'],
      icon: '🛍️',
      description: 'Golf pro shop'
    },
    'club_rental' => {
      keywords: ['club rental', 'rental clubs', 'equipment rental'],
      icon: '⛳',
      description: 'Golf club rental available'
    },
    'cart_rental' => {
      keywords: ['cart rental', 'golf cart', 'cart included'],
      icon: '🚗',
      description: 'Golf cart rental available'
    },
    'golf_lessons' => {
      keywords: ['golf lessons', 'instruction', 'golf pro', 'teaching'],
      icon: '👨‍🏫',
      description: 'Golf instruction and lessons'
    }
  },

  # Course Features
  course_features: {
    'walking_only' => {
      keywords: ['walking only', 'no carts', 'walk only'],
      icon: '🚶',
      description: 'Walking only course (no carts)'
    },
    'cart_paths_only' => {
      keywords: ['cart path only', 'cart paths', 'path only'],
      icon: '🛤️',
      description: 'Carts restricted to paths only'
    },
    'water_features' => {
      keywords: ['water hazards', 'lakes', 'ponds', 'streams'],
      icon: '💧',
      description: 'Significant water features'
    },
    'desert_course' => {
      keywords: ['desert', 'desert golf', 'desert course'],
      icon: '🌵',
      description: 'Desert-style golf course'
    }
  },

  # Facilities & Amenities
  facilities: {
    'clubhouse' => {
      keywords: ['clubhouse', 'club house'],
      icon: '🏛️',
      description: 'Golf clubhouse'
    },
    'locker_room' => {
      keywords: ['locker room', 'lockers', 'changing room'],
      icon: '🚿',
      description: 'Locker room facilities'
    },
    'spa' => {
      keywords: ['spa', 'massage', 'wellness'],
      icon: '💆',
      description: 'Spa and wellness facilities'
    },
    'fitness_center' => {
      keywords: ['fitness', 'gym', 'workout'],
      icon: '💪',
      description: 'Fitness center or gym'
    },
    'swimming_pool' => {
      keywords: ['pool', 'swimming', 'aquatic'],
      icon: '🏊',
      description: 'Swimming pool'
    },
    'tennis' => {
      keywords: ['tennis', 'tennis court'],
      icon: '🎾',
      description: 'Tennis facilities'
    }
  },

  # Accommodation & Resort
  accommodation: {
    'lodging' => {
      keywords: ['hotel', 'resort', 'lodging', 'accommodation', 'rooms'],
      icon: '🏨',
      description: 'On-site lodging available'
    },
    'conference_facilities' => {
      keywords: ['conference', 'meeting', 'business center'],
      icon: '💼',
      description: 'Conference and meeting facilities'
    }
  },

  # Special Features
  special: {
    'tournament_host' => {
      keywords: ['tournament', 'championship', 'pga', 'tour'],
      icon: '🏆',
      description: 'Hosts tournaments or championships'
    },
    'wedding_venue' => {
      keywords: ['wedding', 'weddings', 'ceremony'],
      icon: '💒',
      description: 'Wedding venue and services'
    },
    'corporate_events' => {
      keywords: ['corporate', 'business events', 'outings'],
      icon: '🤝',
      description: 'Corporate event hosting'
    }
  }
}.freeze

# Helper methods for amenity processing
class GolfAmenityProcessor
  def self.all_amenities
    GOLF_AMENITIES.values.flat_map(&:keys)
  end

  def self.amenities_by_category
    GOLF_AMENITIES
  end

  def self.find_amenities_in_text(text)
    found_amenities = []
    text_lower = text.downcase

    GOLF_AMENITIES.each do |category, amenities|
      amenities.each do |amenity_key, amenity_data|
        amenity_data[:keywords].each do |keyword|
          if text_lower.include?(keyword)
            found_amenities << amenity_key
            break # Found this amenity, move to next
          end
        end
      end
    end

    found_amenities.uniq
  end

  def self.get_amenity_info(amenity_key)
    GOLF_AMENITIES.values.each do |category|
      return category[amenity_key] if category[amenity_key]
    end
    nil
  end

  def self.amenity_display_name(amenity_key)
    amenity_key.humanize
  end

  def self.amenity_icon(amenity_key)
    info = get_amenity_info(amenity_key)
    info ? info[:icon] : '⭐'
  end
end 