# Define tag categories for display in the UI using standardized tags
TAG_CATEGORIES = {
  "Golf Experience" => [
    "golf:top100", 
    "golf:bucket_list", 
    "golf:championship", 
    "golf:pga_tour", 
    "golf:major_championship"
  ],
  
  "Course Style" => [
    "golf:links", 
    "golf:parkland", 
    "golf:desert", 
    "golf:mountain", 
    "golf:resort", 
    "golf:historic"
  ],
  
  "Layout Features" => [
    "layout:water_hazards", 
    "layout:elevation_changes", 
    "layout:tree_lined", 
    "layout:island_greens",
    "layout:bunkers", 
    "layout:doglegs", 
    "layout:narrow_fairways", 
    "layout:wide_fairways"
  ],
  
  "Playability" => [
    "play:walkable", 
    "play:cart_required", 
    "play:beginner_friendly", 
    "play:challenging", 
    "play:well_maintained"
  ],
  
  "Trip Type" => [
    "trip:luxury", 
    "trip:pure_golf",
    "trip:buddies", 
    "trip:weekend", 
    "trip:group_friendly", 
    "trip:remote"
  ],
  
  "Course Amenities" => [
    "amenity:onsite_lodging", 
    "amenity:multiple_courses", 
    "amenity:caddie_service", 
    "amenity:nightlife"
  ]
}

# Legacy layout tags (now merged into course_tags with layout: prefix)
LEGACY_LAYOUT_TAGS = [
  'water holes',
  'elevation changes',
  'tree lined',
  'links style',
  'island greens',
  'bunkers',
  'dog legs',
  'narrow fairways',
  'wide fairways'
]

# Helper method to get display name for a tag
def self.display_name_for_tag(tag)
  case tag
  when /^golf:(.+)/
    $1.titleize
  when /^layout:(.+)/
    $1.titleize
  when /^play:(.+)/
    $1.titleize
  when /^trip:(.+)/
    $1.titleize
  when /^amenity:(.+)/
    $1.titleize
  else
    tag.titleize
  end
end 