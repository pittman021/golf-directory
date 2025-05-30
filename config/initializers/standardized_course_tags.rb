# Standardized Course Tags Configuration
# This defines the clean, standardized tags we want to use going forward

STANDARDIZED_COURSE_TAGS = {
  # Golf Experience & Prestige
  "golf:top100" => "Top 100 Course",
  "golf:bucket_list" => "Bucket List",
  "golf:championship" => "Championship Venue", 
  "golf:pga_tour" => "PGA Tour Host",
  "golf:major_championship" => "Major Championship Host",
  
  # Course Style & Design
  "golf:links" => "Links Style",
  "golf:parkland" => "Parkland",
  "golf:desert" => "Desert Course",
  "golf:mountain" => "Mountain Course",
  "golf:resort" => "Resort Course",
  "golf:historic" => "Historic Course",
  
  # Layout Features
  "layout:water_hazards" => "Water Hazards",
  "layout:elevation_changes" => "Elevation Changes", 
  "layout:tree_lined" => "Tree Lined",
  "layout:island_greens" => "Island Greens",
  "layout:bunkers" => "Strategic Bunkers",
  "layout:doglegs" => "Dogleg Holes",
  "layout:narrow_fairways" => "Narrow Fairways",
  "layout:wide_fairways" => "Wide Fairways",
  
  # Difficulty & Playability
  "play:walkable" => "Walking Friendly",
  "play:cart_required" => "Cart Required",
  "play:beginner_friendly" => "Beginner Friendly", 
  "play:challenging" => "Challenging",
  "play:well_maintained" => "Well Maintained",
  
  # Trip & Experience Type
  "trip:luxury" => "Luxury Experience",
  "trip:pure_golf" => "Pure Golf Experience",
  "trip:buddies" => "Great for Buddies Trip",
  "trip:weekend" => "Weekend Getaway",
  "trip:group_friendly" => "Group Friendly",
  "trip:remote" => "Remote/Destination",
  
  # Amenities (these should eventually move to amenity tags)
  "amenity:onsite_lodging" => "On-site Lodging",
  "amenity:multiple_courses" => "Multiple Courses",
  "amenity:caddie_service" => "Caddie Service Available",
  "amenity:nightlife" => "Great Nightlife Nearby"
}.freeze

# Mapping of current messy tags to standardized tags
TAG_CLEANUP_MAPPING = {
  # Top 100 variations
  "top_100_courses" => "golf:top100",
  
  # Links variations
  "links" => "golf:links",
  "links style" => "golf:links", 
  "links-style" => "golf:links",
  
  # Layout features - normalize naming
  "water holes" => "layout:water_hazards",
  "water-features" => "layout:water_hazards",
  "water-views" => "layout:water_hazards",
  "elevation changes" => "layout:elevation_changes",
  "elevation-changes" => "layout:elevation_changes", 
  "tree lined" => "layout:tree_lined",
  "tree-lined" => "layout:tree_lined",
  "island greens" => "layout:island_greens",
  "dog legs" => "layout:doglegs",
  "narrow fairways" => "layout:narrow_fairways",
  "wide fairways" => "layout:wide_fairways",
  "bunkers" => "layout:bunkers",
  
  # Course styles
  "desert" => "golf:desert",
  "mountain" => "golf:mountain", 
  "mountain-views" => "golf:mountain",
  "resort" => "golf:resort",
  "resort-style" => "golf:resort",
  "parkland" => "golf:parkland",
  "coastal" => "golf:links", # coastal often means links-style
  "lakeside" => "layout:water_hazards",
  "hill-country" => "golf:mountain",
  "historic" => "golf:historic",
  "classic" => "golf:historic",
  
  # Championships and events
  "pga_event_host" => "golf:pga_tour",
  "major_championship_host" => "golf:major_championship", 
  "championship" => "golf:championship",
  "tournament-venue" => "golf:championship",
  
  # Trip types
  "buddies_trip" => "trip:buddies",
  "weekend_trip" => "trip:weekend", 
  "group_friendly" => "trip:group_friendly",
  "luxury" => "trip:luxury",
  "remote" => "trip:remote",
  
  # Playability
  "walkable" => "play:walkable",
  "walking-friendly" => "play:walkable",
  "walking-only" => "play:walkable",
  "beginner-friendly" => "play:beginner_friendly",
  "family-friendly" => "play:beginner_friendly",
  "challenging" => "play:challenging",
  "well-maintained" => "play:well_maintained",
  "strategic" => "play:challenging",
  
  # Amenities
  "onsite_lodging" => "amenity:onsite_lodging",
  "multiple_courses" => "amenity:multiple_courses", 
  "caddie_optional" => "amenity:caddie_service",
  "great_nightlife" => "amenity:nightlife",
  
  # Bucket list - this could be either pure golf or luxury depending on the course
  "bucket_list" => "golf:bucket_list",
  
  # Architects (these might be better as separate fields)
  "fazio-design" => nil, # Remove - should be architect field
  "coore-crenshaw" => nil, # Remove - should be architect field  
  "tillinghast" => nil, # Remove - should be architect field
  "palmer-design" => nil, # Remove - should be architect field
  "troon" => nil, # Remove - this is management company
  
  # Recently renovated (temporal, should be handled differently)
  "renovation" => nil, # Remove - temporal information
  "recently-renovated" => nil, # Remove - temporal information
}.freeze

# Tags to completely remove (non-golf related or system tags)
TAGS_TO_REMOVE = [
  # Google Places API pollution
  "point_of_interest", "establishment", "food", "restaurant", "health", "store",
  "bar", "gym", "tourist_attraction", "lodging", "spa", "cafe", "meal_takeaway",
  "night_club", "rv_park", "real_estate_agency", "transit_station", "school",
  "political", "general_contractor", "finance", "locality", "local_government_office",
  "clothing_store", "travel_agency", "car_wash", "amusement_park", "campground",
  "car_repair", "atm", "hair_care", "car_dealer", "shopping_mall", "bowling_alley",
  "colloquial_area",
  
  # System/import tags
  "csv-import", "google-enriched", "freegolftracker", "imported",
  
  # Quality tiers (should be separate field)
  "premium", "notable", "standard", "minimal", "public",
  
  # Vague/unclear tags
  "accessible", "local-favorite"
].freeze

# Helper method to get clean tag display name
def self.display_name_for_tag(tag)
  STANDARDIZED_COURSE_TAGS[tag] || tag.titleize
end

# Helper method to get emoji for tag (integrates with existing TagEmojiService)
def self.emoji_for_tag(tag)
  TagEmojiService.emoji_for(tag)
end 