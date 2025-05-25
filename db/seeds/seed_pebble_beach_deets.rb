details = {
  "destination_overview": "A world-class golf destination on California's Monterey Peninsula, Pebble Beach is known for its cliffside ocean holes, top-ranked public courses, and walkable layouts. It's a must-play for golfers chasing iconic rounds.",
  "getting_there": {
    "airport": "Monterey Regional Airport (15 mins)",
    "drive": "2 hours from San Francisco, 5 hours from LAX",
    "shuttle_tips": "Use resort shuttles — they're fast and more convenient than driving between courses."
  },
  "weather_notes": [
    "May and June often bring coastal fog ('May Gray' / 'June Gloom') that can obscure views until noon.",
    "September and October are typically the clearest and driest months.",
    "Pack for all conditions — temperatures range from 50–70°F year-round."
  ],
  "calendar_notes": [
    {
      "event": "AT&T Pebble Beach Pro-Am",
      "dates": "Early February",
      "note": "Tee times at Pebble and Spyglass are blocked for several days. Avoid if you're not attending the event."
    },
    {
      "event": "USGA Qualifiers (Bayonet & Blackhorse)",
      "dates": "Late July",
      "note": "Expect course closures or heavy traffic."
    }
  ],
  "course_conditions": {
    "last_updated": "2025-05-25",
    "notes": "Old Mac and Trails in good shape. Sheep Ranch greens are bumpy. Conditions reported as mixed. Consider checking course pages for the latest info.",
    "condition_level": "fair",
    "ratings": {
      "Pebble Beach": 6,
      "Spyglass Hill": 9,
      "Spanish Bay": 7,
      "Poppy Hills": 8
    }
  },
  "recommended_play_order": [
    "Spanish Bay",
    "Spyglass Hill",
    "Pebble Beach"
  ],
  "tee_time_tips": [
    "Avoid late afternoon rounds after November — daylight fades fast.",
    "7:00–8:00am tee times are best for pace and light.",
    "3:00pm tee times may not finish in fall/winter, even if 'guaranteed'."
  ],
  "lodging_summary": [
    {
      "name": "The Inn at Spanish Bay",
      "note": "Quieter, more relaxed setting with easy access to the Spanish Bay course."
    },
    {
      "name": "The Lodge at Pebble Beach",
      "note": "Iconic experience — ask for a room overlooking the 18th green."
    },
    {
      "name": "Casa Palmero",
      "note": "Boutique, peaceful, ideal for couples."
    },
    {
      "name": "Pacific Grove B&Bs / Airbnbs",
      "note": "Affordable and charming local alternatives with walkability."
    }
  ],
  "alt_courses": [
    {
      "name": "Pacific Grove Golf Links",
      "note": "Affordable muni with a scenic back nine. Great filler round."
    },
    {
      "name": "Poppy Hills",
      "note": "Challenging and well-kept. Former PGA Tour stop. NCGA members get a discount."
    },
    {
      "name": "Pasatiempo",
      "note": "MacKenzie-designed gem in Santa Cruz. Historic and playable — worth the drive."
    },
    {
      "name": "Bayonet & Blackhorse",
      "note": "USGA-caliber test with coastal views. Good alt for serious golfers."
    }
  ],
  "trip_tips": [
    "Use waterproof shoes in morning rounds",
    "Bring chapstick — it's windy",
    "Use a putter off tight lies around greens",
    "Club up into wind",
    "Take advantage of the shuttle system"
  ],
  "golf_packages": [
    {
      "title": "Stay & Play at The Lodge",
      "provider": "Pebble Beach Resorts",
      "details": "Includes 2 nights at The Lodge, 2 rounds (Spyglass + Pebble), and daily breakfast.",
      "price_estimate": "$2,750 per golfer",
      "booking_note": "Available year-round. Higher rates apply during Pro-Am week."
    },
    {
      "title": "Midweek Escape – Spanish Bay",
      "provider": "Pebble Beach Resorts",
      "details": "1-night stay + 1 round at Spanish Bay. Caddie optional.",
      "price_estimate": "$1,100 per golfer",
      "booking_note": "Best rates in Jan–Feb and Nov."
    },
    {
      "title": "Airbnb Combo + Public Courses",
      "provider": "DIY",
      "details": "Stay in Pacific Grove Airbnb + play Pacific Grove, Poppy Hills, Bayonet. Book separately.",
      "price_estimate": "$750–$1,200 total trip",
      "booking_note": "Best value option for budget travelers."
    }
  ]
}


require 'json'

puts "Seeding Pebble Beach details..."

location = Location.find_by(slug: 'pebble-beach')

if location.nil?
  puts "Location not found!"
  exit
end

location.update!(details_json: details)

puts "✅ Pebble Beach details_json updated!"
