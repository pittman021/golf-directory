# Standardized Golf Course Amenities
# Based on analysis of common amenities and web scraping results

STANDARDIZED_AMENITIES = [
  # Core Golf Facilities (most common)
  "Driving Range",
  "Putting Green", 
  "Short Game Area",
  "Practice Facility",
  
  # Pro Shop & Services
  "Pro Shop",
  "Club Rentals",
  "Golf Lessons",
  "Golf Carts", # Assumed standard but worth tracking
  
  # Dining & Social
  "Restaurant",
  "Bar",
  "Snack Bar",
  "Beverage Cart",
  
  # Facilities & Amenities
  "Clubhouse",
  "Locker Rooms",
  "Spa",
  "Fitness Center",
  
  # Accommodation & Events
  "Lodging",
  "Event Space",
  "Tournament Host",
  "Wedding Venue",
  "Conference Facilities",
  "Banquet Facilities",
  
  # Premium Services
  "Caddies Available",
  "Bag Drop Service",
  
  # Course Features
  "Desert Course",
  "Water Features",
  "Walking Only",
  "Cart Path Only"
].freeze

# Mapping rules to convert our detailed amenities to standardized ones
AMENITY_MAPPING = {
  # Golf Facilities
  'driving_range' => 'Driving Range',
  'putting_green' => 'Putting Green',
  'chipping_green' => 'Short Game Area',
  'practice_facility' => 'Practice Facility',
  
  # Pro Shop & Services  
  'pro_shop' => 'Pro Shop',
  'club_rental' => 'Club Rentals',
  'cart_rental' => 'Golf Carts',
  'golf_lessons' => 'Golf Lessons',
  
  # Dining
  'restaurant' => 'Restaurant',
  'bar' => 'Bar',
  'snack_bar' => 'Snack Bar',
  
  # Facilities
  'clubhouse' => 'Clubhouse',
  'locker_room' => 'Locker Rooms',
  'spa' => 'Spa',
  'fitness_center' => 'Fitness Center',
  
  # Accommodation & Events
  'lodging' => 'Lodging',
  'banquet_facilities' => 'Banquet Facilities',
  'conference_facilities' => 'Conference Facilities',
  'tournament_host' => 'Tournament Host',
  'wedding_venue' => 'Wedding Venue',
  'corporate_events' => 'Event Space',
  
  # Course Features
  'desert_course' => 'Desert Course',
  'water_features' => 'Water Features',
  'walking_only' => 'Walking Only',
  'cart_paths_only' => 'Cart Path Only',
  'swimming_pool' => 'Swimming Pool',
  'tennis' => 'Tennis Courts'
}.freeze

class StandardizedAmenityProcessor
  def self.standardize_amenities(raw_amenities)
    return [] unless raw_amenities.present?
    
    standardized = raw_amenities.map do |amenity|
      AMENITY_MAPPING[amenity] || amenity.humanize
    end
    
    # Remove duplicates and sort
    standardized.uniq.sort
  end
  
  def self.all_standard_amenities
    STANDARDIZED_AMENITIES
  end
  
  def self.validate_amenity(amenity)
    STANDARDIZED_AMENITIES.include?(amenity)
  end
  
  # Get amenities by category for display
  def self.categorize_amenities(amenities)
    categories = {
      'Golf Facilities' => ['Driving Range', 'Putting Green', 'Short Game Area', 'Practice Facility'],
      'Pro Shop & Services' => ['Pro Shop', 'Club Rentals', 'Golf Lessons', 'Golf Carts'],
      'Dining & Social' => ['Restaurant', 'Bar', 'Snack Bar', 'Beverage Cart'],
      'Facilities' => ['Clubhouse', 'Locker Rooms', 'Spa', 'Fitness Center'],
      'Events & Accommodation' => ['Lodging', 'Event Space', 'Tournament Host', 'Wedding Venue', 'Conference Facilities', 'Banquet Facilities'],
      'Course Features' => ['Desert Course', 'Water Features', 'Walking Only', 'Cart Path Only']
    }
    
    result = {}
    categories.each do |category, category_amenities|
      found = amenities & category_amenities
      result[category] = found if found.any?
    end
    
    result
  end
end 