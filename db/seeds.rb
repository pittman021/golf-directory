# db/seeds.rb

# Price tiers:
# $ = Budget ($0-60)
# $$ = Mid ($61-150)
# $$$ = Premium ($151-300)
# $$$$ = Luxury ($300+)

puts "Cleaning the database..."
Location.destroy_all
Course.destroy_all
User.destroy_all
Review.destroy_all

# Create admin user
puts "Creating admin user..."
admin = User.create!(
  email: 'tim@admin.com',
  password: 'admin123',
  username: 'admin',
  role: 'admin'
)
puts "Admin user created: #{admin.email}"

# Create some users for reviews
puts "Creating users..."
users = [
  User.create!(
    email: 'john@example.com',
    password: 'password123',
    username: 'GolfPro'
  ),
  User.create!(
    email: 'jane@example.com',
    password: 'password123',
    username: 'GolfLover'
  ),
  User.create!(
    email: 'bob@example.com',
    password: 'password123',
    username: 'TeeTime'
  )
]

# Original locations with courses
original_locations = [
  {
    name: 'Pebble Beach',
    description: 'Home to some of the most beautiful and challenging courses in the world',
    latitude: 36.5725,
    longitude: -121.9486,
    region: 'West',
    state: 'California',
    country: 'USA',
    best_months: 'July through August',
    nearest_airports: 'Monterey Regional Airport (MRY)',
    weather_info: 'Mediterranean climate with mild temperatures year-round',
    avg_lodging_cost_per_night: 450,  # Luxury resort area
    courses_attributes: [
      {
        name: "Pebble Beach Golf Links",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 575,
        description: "One of the most famous public courses in the world",
        yardage: 7_075,
        par: 72,
        layout_tags: ['ocean views', 'links style', 'championship venue', 'clifftop holes'],
        notes: "Iconic oceanside links featuring stunning clifftop holes. Host of multiple U.S. Opens.",
        reviews_attributes: [
          {
            user: users[0],
            rating: 5,
            played_on: Date.today - 30,
            course_condition: "Excellent",
            comment: "Bucket list course that lives up to the hype. Incredible ocean views and perfect conditions."
          },
          {
            user: users[1],
            rating: 5,
            played_on: Date.today - 15,
            course_condition: "Excellent",
            comment: "Worth every penny. The most beautiful golf course I've ever played."
          }
        ]
      },
      {
        name: "Spyglass Hill Golf Course",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 395,
        description: "Challenging course with beautiful forest and ocean views",
        yardage: 6_960,
        par: 72,
        layout_tags: ['ocean views', 'forest', 'elevation changes', 'dog legs'],
        notes: "Robert Trent Jones Sr. design combining coastal dunes and forest. First five holes offer ocean views.",
        reviews_attributes: [
          {
            user: users[2],
            rating: 4,
            played_on: Date.today - 20,
            course_condition: "Very Good",
            comment: "Challenging but fair. The forest holes are amazing."
          }
        ]
      }
    ]
  },
  # ... [previous locations remain the same as they already use the correct format] ...
]

# Minnesota locations with updated price tiers
minnesota_locations = [
  {
    name: "Madden's on Gull Lake",
    region: "Midwest",
    state: "Minnesota",
    country: "USA",
    description: "Historic resort featuring multiple championship golf courses on Gull Lake",
    latitude: 46.4257,
    longitude: -94.3714,
    nearest_airports: "Brainerd Lakes Regional Airport (BRD)",
    weather_info: "Best season: May to September; Summer temperatures average 70-80°F",
    avg_lodging_cost_per_night: 225,  # Resort area
    courses_attributes: [
      {
        name: "Pine Beach East",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee: 129,
        description: "Championship course with scenic lake views",
        yardage: 6_101,
        par: 72,
        layout_tags: ['lake views', 'tree lined', 'bunkers', 'traditional'],
        notes: "Classic Minnesota resort course with scenic Gull Lake views. Strategic bunkering throughout."
      },
      {
        name: "Pine Beach West",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee: 59,
        description: "Classic resort course suitable for all skill levels",
        yardage: 5_832,
        par: 71,
        layout_tags: ['lake views', 'wide fairways', 'beginner friendly', 'traditional'],
        notes: "Family-friendly resort course featuring gentle elevation changes and forgiving fairways."
      }
    ]
  }
]

# Myrtle Beach locations with updated price tiers
myrtle_beach_locations = [
  {
    name: 'Myrtle Beach',
    description: 'Known as the "Golf Capital of the World," Myrtle Beach offers over 80 championship golf courses along the Grand Strand.',
    latitude: 33.6891,
    longitude: -78.8867,
    region: 'Southeast',
    state: 'South Carolina',
    country: 'USA',
    best_months: 'March through May, September through November',
    nearest_airports: 'Myrtle Beach International Airport (MYR)',
    weather_info: 'Subtropical climate with hot summers and mild winters. Spring and fall offer ideal golfing conditions.',
    avg_lodging_cost_per_night: 200,  # Various options available
    courses_attributes: [
      {
        name: "TPC Myrtle Beach",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 189,
        description: "Former host of the Senior PGA Tour Championship",
        yardage: 6_950,
        par: 72,
        layout_tags: ['water holes', 'tree lined', 'tournament venue', 'strategic'],
        notes: "Tom Fazio design with tour-caliber conditions. Challenging layout with water features on 10 holes.",
        website_url: "https://www.tpcmyrtlebeach.com"
      },
      {
        name: "Dunes Golf and Beach Club",
        course_type: :private_course,
        number_of_holes: 18,
        green_fee: 349,
        description: "Robert Trent Jones Sr. masterpiece",
        yardage: 7_450,
        par: 72,
        layout_tags: ['ocean views', 'water holes', 'traditional', 'championship venue'],
        notes: "Historic design with the famous 'Waterloo' par-5 13th hole wrapping around Lake Singleton.",
        website_url: "https://www.thedunesclub.net"
      },
      {
        name: "Caledonia Golf & Fish Club",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 199,
        description: "Built on a historic rice plantation",
        yardage: 6_526,
        par: 70,
        layout_tags: ['lowcountry', 'tree lined', 'water holes', 'strategic'],
        notes: "Mike Strantz masterpiece with live oaks draped in Spanish moss framing the fairways.",
        website_url: "https://www.caledoniagolfandfishclub.com"
      },
      {
        name: "Barefoot Resort - Love Course",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee: 169,
        description: "Davis Love III's tribute to the Lowcountry",
        yardage: 7_047,
        par: 72,
        layout_tags: ['wide fairways', 'lowcountry', 'resort style', 'strategic'],
        notes: "Features recreated ruins of an old plantation home. Wide fairways and challenging green complexes.",
        website_url: "https://www.barefootgolf.com"
      }
    ]
  }
]

charleston_locations = [
  {
    name: 'Charleston',
    description: 'Historic coastal city offering a perfect blend of championship golf, lowcountry charm, and southern hospitality. Known for its year-round golf weather and diverse course designs.',
    latitude: 32.7765,
    longitude: -79.9311,
    region: 'Southeast',
    state: 'South Carolina',
    country: 'USA',
    best_months: 'March through May, September through November',
    nearest_airports: 'Charleston International Airport (CHS)',
    weather_info: 'Subtropical climate with mild winters and warm summers. Spring and fall offer ideal golfing conditions.',
    avg_lodging_cost_per_night: 275,  # Upscale tourist destination
    tags: ['coastal', 'historic', 'lowcountry'],
    courses_attributes: [
      {
        name: "Ocean Course at Kiawah Island",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee: 395,
        description: "Pete Dye's masterpiece and host of the 2021 PGA Championship. Known for its seaside setting and challenging winds.",
        yardage: 7876,
        par: 72,
        website_url: "https://kiawahresort.com/golf/the-ocean-course/",
        latitude: 32.6082,
        longitude: -80.0821,
        layout_tags: ['ocean views', 'links style', 'water holes', 'championship venue'],
        notes: "Ranked #1 public course in South Carolina. All 18 holes offer views of the Atlantic Ocean. Host of the 1991 Ryder Cup and 2012/2021 PGA Championships.",
        reviews_attributes: [
          {
            user: users[0],
            rating: 5,
            played_on: Date.today - 30,
            course_condition: "Excellent",
            comment: "One of the best golf experiences in the world. Every hole is memorable."
          }
        ]
      },
      {
        name: "Wild Dunes Links Course",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee: 189,
        description: "Tom Fazio's first solo design, featuring stunning coastal holes and challenging seaside winds.",
        yardage: 6709,
        par: 72,
        website_url: "https://www.wilddunes.com/golf/",
        latitude: 32.8139,
        longitude: -79.7341,
        layout_tags: ['ocean views', 'links style', 'water holes', 'coastal'],
        notes: "Spectacular finishing holes along the Atlantic Ocean. Recently renovated with new salt-tolerant grass and enhanced bunkers.",
        reviews_attributes: [
          {
            user: users[1],
            rating: 4,
            played_on: Date.today - 15,
            course_condition: "Very Good",
            comment: "Beautiful coastal course with great variety. Ocean holes are spectacular."
          }
        ]
      },
      {
        name: "Patriots Point Links",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 89,
        description: "Harbor-side municipal course offering stunning views of Charleston Harbor and the city skyline.",
        yardage: 6955,
        par: 72,
        website_url: "https://patriotspointlinks.com/",
        latitude: 32.7857,
        longitude: -79.9053,
        layout_tags: ['harbor views', 'water holes', 'wide fairways', 'scenic'],
        notes: "Best value course in Charleston area. Views of Fort Sumter, Charleston Harbor, and the USS Yorktown aircraft carrier.",
        reviews_attributes: [
          {
            user: users[2],
            rating: 4,
            played_on: Date.today - 45,
            course_condition: "Good",
            comment: "Great value with incredible harbor views. Perfect for a casual round."
          }
        ]
      },
      {
        name: "Charleston National Golf Club",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 129,
        description: "Rees Jones design weaving through marshland and coastal forest.",
        yardage: 7117,
        par: 72,
        website_url: "https://charlestonnationalgolf.com/",
        latitude: 32.8482,
        longitude: -79.7763,
        layout_tags: ['marsh views', 'tree lined', 'water holes', 'strategic'],
        notes: "Premium public access course with numerous holes along the Intracoastal Waterway. Known for excellent course conditions and challenging layout.",
        reviews_attributes: [
          {
            user: users[0],
            rating: 4,
            played_on: Date.today - 60,
            course_condition: "Very Good",
            comment: "Hidden gem with great marsh views. Challenging but fair layout."
          }
        ]
      },
      {
        name: "RiverTowne Country Club",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee: 149,
        description: "Arnold Palmer signature design along the Wando River.",
        yardage: 6955,
        par: 72,
        website_url: "https://rivertownecountryclub.com/",
        latitude: 32.8975,
        longitude: -79.8241,
        layout_tags: ['river views', 'lowcountry', 'water holes', 'strategic'],
        notes: "Beautiful Palmer design featuring marsh and river views. Multiple holes along the Wando River provide scenic challenges.",
        reviews_attributes: [
          {
            user: users[1],
            rating: 4,
            played_on: Date.today - 25,
            course_condition: "Very Good",
            comment: "Great layout with beautiful views. Classic Palmer design elements throughout."
          }
        ]
      }
    ]
  }
]

# Add Charleston to the locations to be created
locations = original_locations + minnesota_locations + myrtle_beach_locations + charleston_locations

# Create all locations and their associated courses
locations.each do |location_data|
  courses_attributes = location_data.delete(:courses_attributes)
  location = Location.create!(location_data)
  
  courses_attributes.each do |course_data|
    reviews_attributes = course_data.delete(:reviews_attributes)
    course = Course.create!(course_data)
    LocationCourse.create!(location: location, course: course)
    
    if reviews_attributes
      reviews_attributes.each do |review_data|
        Review.create!(review_data.merge(course: course))
      end
    end
  end
end

# Add to db/seeds.rb or run in rails console

golf_destinations = [
  {
    name: "Kohler",
    description: "Home to the legendary Whistling Straits and Blackwolf Run, Kohler is a premier Midwest golf destination featuring Pete Dye masterpieces along Lake Michigan. The Straits course, host of the 2021 Ryder Cup, offers a links-style experience with stunning lakeside views.",
    latitude: 43.7394,
    longitude: -87.7840,
    region: "Midwest",
    state: "Wisconsin",
    country: "USA",
    best_months: "June through September",
    nearest_airports: "Milwaukee Mitchell International Airport (MKE)",
    weather_info: "Warm summers and cold winters. Peak golf season is late spring through early fall. Lake Michigan influences local weather with occasional strong winds.",
    avg_lodging_cost_per_night: 350,
    tags: ["lakeside", "resort style", "championship venue"]
  },
  {
    name: "Farmingdale",
    description: "Home to the legendary Bethpage State Park golf complex, featuring five public courses including the world-renowned Black Course, a multiple U.S. Open venue known for its difficulty and championship pedigree.",
    latitude: 40.7329,
    longitude: -73.4432,
    region: "Northeast",
    state: "New York",
    country: "USA",
    best_months: "May through October",
    nearest_airports: "John F. Kennedy International Airport (JFK), LaGuardia Airport (LGA)",
    weather_info: "Four distinct seasons with warm summers and cold winters. Best golf conditions in late spring and early fall.",
    avg_lodging_cost_per_night: 200,
    tags: ["public golf", "historic", "championship venue"]
  },
  {
    name: "Ponte Vedra Beach",
    description: "Home to TPC Sawgrass and PGA Tour headquarters, this Florida golf destination is famous for its championship courses and iconic island green 17th hole at THE PLAYERS Stadium Course.",
    latitude: 30.2400,
    longitude: -81.3853,
    region: "Southeast",
    state: "Florida",
    country: "USA",
    best_months: "October through May",
    nearest_airports: "Jacksonville International Airport (JAX)",
    weather_info: "Subtropical climate with mild winters and hot summers. Year-round golf with best conditions in spring and fall.",
    avg_lodging_cost_per_night: 400,
    tags: ["coastal", "resort style", "championship venue"]
  },
  {
    name: "Streamsong",
    description: "A modern golf resort featuring three distinct courses (Red, Blue, and Black) built on former phosphate mining land, offering a unique links-style experience in central Florida.",
    latitude: 27.6661,
    longitude: -81.9320,
    region: "Southeast",
    state: "Florida",
    country: "USA",
    best_months: "November through April",
    nearest_airports: "Tampa International Airport (TPA), Orlando International Airport (MCO)",
    weather_info: "Subtropical climate with hot summers. Peak season is winter months with mild temperatures and lower humidity.",
    avg_lodging_cost_per_night: 450,
    tags: ["resort style", "modern", "links style"]
  },
  {
    name: "Nekoosa",
    description: "Home to Sand Valley Golf Resort, a modern golf destination built on dramatic sand dunes in central Wisconsin, featuring world-class courses designed by leading architects.",
    latitude: 44.3230,
    longitude: -89.9001,
    region: "Midwest",
    state: "Wisconsin",
    country: "USA",
    best_months: "May through October",
    nearest_airports: "Central Wisconsin Airport (CWA)",
    weather_info: "Continental climate with warm summers and cold winters. Peak golf season is late spring through early fall.",
    avg_lodging_cost_per_night: 300,
    tags: ["modern", "resort style", "scenic views"]
  },
  {
    name: "Sea Island",
    description: "Luxury coastal golf resort featuring multiple courses, including the Seaside Course, home of the PGA Tours RSM Classic, offering Southern hospitality and championship golf.",
    latitude: 31.1987,
    longitude: -81.3975,
    region: "Southeast",
    state: "Georgia",
    country: "USA",
    best_months: "March through November",
    nearest_airports: "Brunswick Golden Isles Airport (BQK), Jacksonville International Airport (JAX)",
    weather_info: "Coastal climate with mild winters and hot summers. Year-round golf with best conditions in spring and fall.",
    avg_lodging_cost_per_night: 500,
    tags: ["coastal", "resort style", "luxury"]
  }
]

# Create the locations
golf_destinations.each do |destination|
  Location.create!(destination)
end

# Now let's add the courses in a separate loop
courses_data = {
  "Kohler" => [
    {
      name: "Whistling Straits - Straits Course",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 485,
      description: "Pete Dye masterpiece along Lake Michigan, host of the 2021 Ryder Cup",
      yardage: 7790,
      par: 72,
      layout_tags: ["links style", "lakeside", "championship venue", "pete dye design"],
      notes: "Features eight holes hugging Lake Michigan, nearly 1,000 bunkers, and stunning coastal views."
    },
    {
      name: "Whistling Straits - Irish Course",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 290,
      description: "Inland companion to the Straits course with links-style features",
      yardage: 7201,
      par: 72,
      layout_tags: ["links style", "pete dye design", "strategic", "water holes"],
      notes: "More forgiving than its sister course but still a stern test with grassland and dunes."
    }
  ],
  "Farmingdale" => [
    {
      name: "Bethpage Black",
      course_type: :public_course,
      number_of_holes: 18,
      green_fee: 165,
      description: "A.W. Tillinghast masterpiece and public U.S. Open venue",
      yardage: 7468,
      par: 71,
      layout_tags: ["championship venue", "tree lined", "difficult", "historic"],
      notes: "Warning sign at first tee: The Black Course is an extremely difficult course which we recommend only for highly skilled golfers."
    }
  ],
  "Ponte Vedra Beach" => [
    {
      name: "TPC Sawgrass - THE PLAYERS Stadium Course",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 600,
      description: "Home of THE PLAYERS Championship and the famous island green 17th hole",
      yardage: 7245,
      par: 72,
      layout_tags: ["water holes", "championship venue", "pete dye design", "strategic"],
      notes: "Features one of golfs most famous holes - the island green 17th. Stadium design allows excellent viewing for tournaments."
    }
  ],
  "Streamsong" => [
    {
      name: "Streamsong Red",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 295,
      description: "Coore & Crenshaw design featuring dramatic elevation changes",
      yardage: 7148,
      par: 72,
      layout_tags: ["links style", "modern design", "strategic", "elevation changes"],
      notes: "Built on sand dunes from former phosphate mining, offering firm and fast conditions."
    },
    {
      name: "Streamsong Blue",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 295,
      description: "Tom Doak design intertwined with the Red course",
      yardage: 7176,
      par: 72,
      layout_tags: ["links style", "modern design", "strategic", "water holes"],
      notes: "Features large greens and dramatic bunkering in a links-style setting."
    },
    {
      name: "Streamsong Black",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 295,
      description: "Gil Hanse design on expansive, windswept property",
      yardage: 7331,
      par: 73,
      layout_tags: ["links style", "modern design", "strategic", "wide fairways"],
      notes: "Newest addition to the resort featuring massive greens and bold contours."
    }
  ],
  "Nekoosa" => [
    {
      name: "Sand Valley",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 245,
      description: "Coore & Crenshaw design through dramatic sand dunes",
      yardage: 6913,
      par: 72,
      layout_tags: ["links style", "modern design", "strategic", "elevation changes"],
      notes: "Built on prehistoric sand dunes with firm and fast conditions."
    },
    {
      name: "Mammoth Dunes",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 245,
      description: "David McLay Kidd design featuring massive scale",
      yardage: 6988,
      par: 73,
      layout_tags: ["links style", "modern design", "wide fairways", "dramatic"],
      notes: "Known for its massive scale and playability, with wide fairways and creative green complexes."
    }
  ],
  "Sea Island" => [
    {
      name: "Sea Island Golf Club - Seaside Course",
      course_type: :resort_course,
      number_of_holes: 18,
      green_fee: 425,
      description: "Links-style championship course along the Atlantic Ocean",
      yardage: 7005,
      par: 70,
      layout_tags: ["coastal", "links style", "championship venue", "strategic"],
      notes: "Host of the PGA Tours RSM Classic, featuring coastal views and challenging sea breezes."
    }
  ]
}

# Create courses and associate them with locations
courses_data.each do |location_name, courses|
  location = Location.find_by(name: location_name)
  next unless location

  courses.each do |course_data|
    course = Course.create!(course_data)
    LocationCourse.create!(location: location, course: course)
  end
end

# Create admin user for ActiveAdmin
if Rails.env.development? || Rails.env.production?
  if AdminUser.count == 0 # Only create if no admin exists
    AdminUser.create!(
      email: 'admin@golfdirectory.com',
      password: 'password123',
      password_confirmation: 'password123'
    )
    puts "Admin user created! Email: admin@golfdirectory.com, Password: password123"
    puts "Please change this password immediately after first login!"
  else
    puts "AdminUser already exists - skipping creation"
  end
end

puts "Seeding completed!"