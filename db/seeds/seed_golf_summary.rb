JSONDETAILS = {
"maddens-on-gull-lake" => {
  "destination_overview" => "Madden’s on Gull Lake in Brainerd, Minnesota, is a scenic, full-service golf resort featuring four courses and 63 total holes. With its blend of championship golf, lakeside relaxation, and family-friendly activities, it’s a premier Midwest golf trip destination.",
  "getting_there" => {
    "airport" => "Brainerd Lakes Regional Airport (BRD) – 20 minutes",
    "drive" => "Approximately 2 hours from Minneapolis-St. Paul",
    "shuttle_tips" => "Resort does not offer airport shuttles—rental cars or group vans recommended"
  },
  "weather_notes" => [
    "Golf season runs from early May through mid-October.",
    "May and June offer lush conditions and fewer crowds.",
    "July and August are peak season with warm weather and family travel.",
    "September and early October offer cooler temps, fall colors, and quieter play."
  ],
  "calendar_notes" => [
    {
      "event" => "Opening Weekend",
      "dates" => "May 2–4, 2025",
      "note" => "The Classic and other courses open for the 2025 season—expect busy tee sheets."
    },
    {
      "event" => "Peak Summer Group Events",
      "dates" => "Late June through mid-August",
      "note" => "Many corporate and private tournaments occur—check for course availability."
    }
  ],
  "course_conditions" => {
    "last_updated" => "2025-05-25",
    "notes" => "The Classic is in immaculate shape, with fast, smooth greens and lush fairways. Pine Beach East and West are also in great condition, though East has had mixed reviews in prior seasons. All courses reflect the resort’s high maintenance standards.",
    "ratings" => {
      "The Classic" => 10,
      "Pine Beach East" => 8,
      "Pine Beach West" => 8,
      "Social 9" => 7
    },
    "condition_type" => "excellent"
  },
  "recommended_play_order" => [
    "The Classic",
    "Pine Beach East",
    "Pine Beach West",
    "Social 9"
  ],
  "tee_time_tips" => [
    "Tee times after 6 PM on Pine Beach East offer quiet evening rounds.",
    "The Classic is very popular—book at least 1–2 weeks in advance during peak season.",
    "The Social 9 is great for warm-ups or casual rounds with kids or beginners.",
    "Golf carts are recommended for getting around the large property—drivers must be 18+."
  ],
  "lodging_summary" => [
    {
      "name" => "Golf Villas",
      "note" => "Spacious units overlooking The Classic or Pine Beach courses—ideal for golf groups."
    },
    {
      "name" => "Lakeview Cabins",
      "note" => "Rustic and scenic, close to the lake and main resort amenities."
    },
    {
      "name" => "Lodge Rooms",
      "note" => "Centrally located but some reviews mention dated interiors—budget-friendly option."
    }
  ],
  "alt_courses" => [],
  "trip_tips" => [
    "Make dinner and activity reservations early—some restaurants close by 9 PM.",
    "Mission Point is a guest favorite for lake views and walleye dishes.",
    "The resort is family-friendly—take advantage of the beaches, pools, and kids' programs.",
    "Plan for multiple rounds—63 total holes let you mix competitive and casual play."
  ],
  "food_and_drink": [
    {
      "spot": "Mission Point",
      "note": "Great lakeside dining with a focus on walleye and seasonal fare."
    },
    {
      "spot": "Fairways Restaurant",
      "note": "Casual dining with scenic views of The Classic—convenient for post-round meals."
    },
    {
      "spot": "Lobby Café",
      "note": "Quick breakfast and coffee stop before your tee time."
    }
  ],
  "golf_packages" => [
    {
      "title" => "Classic Deluxe Golf Package",
      "provider" => "Madden’s on Gull Lake",
      "details" => "Includes lodging, daily breakfast and dinner, and golf with cart on all four courses.",
      "price_estimate" => "$850–$1,200 per person for 2–3 nights depending on season and room type",
      "booking_note" => "Best value in spring and fall—call for availability during tournament weekends."
    },
    {
      "title" => "Couples Golf & Spa Getaway",
      "provider" => "Madden’s on Gull Lake",
      "details" => "One round on The Classic, one spa treatment, and lakeside accommodations for two.",
      "price_estimate" => "$1,000+ per couple for 2 nights",
      "booking_note" => "Ideal for mixed-interest trips; book spa appointments early."
    }
  ]
}

}

require 'json'

puts "Seeding golf course details..."

JSONDETAILS.each do |slug_name, details|
  location = Location.find_by(slug: slug_name)

  if location.nil?
    puts "⚠️ #{slug_name} not found!"
    next
  end

  location.update!(details_json: details)
  puts "✅ #{slug_name} details_json updated!"
end

puts "🎉 Golf course details seeding completed!"
