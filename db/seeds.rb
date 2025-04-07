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
    region: 'Monterey Peninsula',
    state: 'California',
    country: 'USA',
    best_months: 'July through August',
    nearest_airports: 'Monterey Regional Airport (MRY)',
    weather_info: 'Mediterranean climate with mild temperatures year-round',
    courses_attributes: [
      {
        name: "Pebble Beach Golf Links",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee_range: "$$$$",  # $575
        description: "One of the most famous public courses in the world",
        yardage: 7_075,
        par: 72,
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
        green_fee_range: "$$$$",  # $395
        description: "Challenging course with beautiful forest and ocean views",
        yardage: 6_960,
        par: 72,
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
    region: "Brainerd Lakes Area",
    state: "Minnesota",
    country: "USA",
    description: "Historic resort featuring multiple championship golf courses on Gull Lake",
    latitude: 46.4257,
    longitude: -94.3714,
    nearest_airports: "Brainerd Lakes Regional Airport (BRD)",
    weather_info: "Best season: May to September; Summer temperatures average 70-80°F",
    courses_attributes: [
      {
        name: "Pine Beach East",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee_range: "$$",    # Changed from "61-79" to "$$" (Mid tier: $61-150)
        description: "Championship course with scenic lake views",
        yardage: 6_101,
        par: 72
      },
      {
        name: "Pine Beach West",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee_range: "$",     # Changed from "41-59" to "$" (Budget tier: $0-60)
        description: "Classic resort course suitable for all skill levels",
        yardage: 5_832,
        par: 71
      }
    ]
  }
]

# Myrtle Beach locations with updated price tiers
myrtle_beach_locations = [
  {
    name: 'Myrtle Beach',
    description: 'Known as the "Golf Capital of the World," Myrtle Beach offers over 80 championship golf courses along the Grand Strand, featuring designs by legendary architects and year-round playable weather.',
    latitude: 33.6891,
    longitude: -78.8867,
    region: 'Grand Strand',
    state: 'South Carolina',
    country: 'USA',
    best_months: 'March through May, September through November',
    nearest_airports: 'Myrtle Beach International Airport (MYR)',
    weather_info: 'Subtropical climate with hot summers and mild winters. Spring and fall offer ideal golfing conditions.',
    courses_attributes: [
      {
        name: "TPC Myrtle Beach",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee_range: "$$$",  # Premium tier ($151-300)
        description: "Former host of the Senior PGA Tour Championship, this Tom Fazio design offers a championship-level challenge with pristine conditions.",
        yardage: 6_950,
        par: 72,
        website_url: "https://www.tpcmyrtlebeach.com",
        latitude: 33.6651,
        longitude: -79.0046,
        reviews_attributes: [
          {
            user: users[0],
            rating: 5,
            played_on: Date.today - 45,
            course_condition: "Excellent",
            comment: "Tour-quality conditions. The back nine is especially challenging with great risk-reward holes."
          },
          {
            user: users[1],
            rating: 4,
            played_on: Date.today - 20,
            course_condition: "Very Good",
            comment: "Challenging course with great practice facilities. Worth the premium price."
          }
        ]
      },
      {
        name: "Dunes Golf and Beach Club",
        course_type: :private_course,
        number_of_holes: 18,
        green_fee_range: "$$$$",  # Luxury tier ($300+)
        description: "Robert Trent Jones Sr. masterpiece featuring the famous 'Waterloo' hole. Host to multiple professional championships.",
        yardage: 7_450,
        par: 72,
        website_url: "https://www.thedunesclub.net",
        latitude: 33.7124,
        longitude: -78.8797,
        reviews_attributes: [
          {
            user: users[2],
            rating: 5,
            played_on: Date.today - 30,
            course_condition: "Excellent",
            comment: "One of the best courses in South Carolina. The ocean views are spectacular."
          }
        ]
      },
      {
        name: "Caledonia Golf & Fish Club",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee_range: "$$$$",  # Luxury tier ($300+)
        description: "Built on a historic rice plantation, this Mike Strantz design is consistently ranked among America's top 100 public courses.",
        yardage: 6_526,
        par: 70,
        website_url: "https://www.caledoniagolfandfishclub.com",
        latitude: 33.5179,
        longitude: -79.0965,
        reviews_attributes: [
          {
            user: users[0],
            rating: 5,
            played_on: Date.today - 60,
            course_condition: "Excellent",
            comment: "Absolutely stunning course. The live oaks and azaleas make every hole picture-perfect."
          }
        ]
      },
      {
        name: "Barefoot Resort - Love Course",
        course_type: :resort_course,
        number_of_holes: 18,
        green_fee_range: "$$$",  # Premium tier ($151-300)
        description: "Davis Love III's tribute to the Lowcountry featuring recreated ruins of an old plantation home.",
        yardage: 7_047,
        par: 72,
        website_url: "https://www.barefootgolf.com",
        latitude: 33.8053,
        longitude: -78.7284,
        reviews_attributes: [
          {
            user: users[1],
            rating: 4,
            played_on: Date.today - 15,
            course_condition: "Very Good",
            comment: "Great layout with some really memorable holes. The ruins add a unique touch."
          }
        ]
      },
      {
        name: "Pine Lakes Country Club",
        course_type: :public_course,
        number_of_holes: 18,
        green_fee_range: "$$",  # Mid tier ($61-150)
        description: "The 'Granddaddy' of Myrtle Beach golf courses, established in 1927. Birthplace of Sports Illustrated magazine.",
        yardage: 6_675,
        par: 70,
        website_url: "https://www.pinelakes.com",
        latitude: 33.7089,
        longitude: -78.8670,
        reviews_attributes: [
          {
            user: users[2],
            rating: 4,
            played_on: Date.today - 25,
            course_condition: "Good",
            comment: "Historic course with great character. The clubhouse is a must-see."
          }
        ]
      }
    ]
  }
]

# New locations to add
new_locations = [
  {
    name: "Bandon Dunes",
    description: "A true links golf destination on the stunning Oregon coast, featuring multiple world-class courses. The resort captures the essence of traditional Scottish links golf with its rugged coastline, rolling dunes, and challenging conditions.",
    latitude: 43.1827,
    longitude: -124.3935,
    region: "Pacific Northwest",
    state: "Oregon",
    country: "United States",
    best_months: "May through October",
    nearest_airports: "Southwest Oregon Regional Airport (OTH) - 30 mins, Portland International Airport (PDX) - 4.5 hours",
    weather_info: "Maritime climate with mild temperatures year-round. Summer highs around 70°F, winter lows in the 40s. Wind is a significant factor, especially in afternoons."
  },
  {
    name: "Sand Valley",
    description: "A premier golf destination in central Wisconsin featuring dramatic sand dunes and ridges created by a prehistoric glacial lake. Offers a unique inland links-style experience with firm and fast conditions.",
    latitude: 44.3333,
    longitude: -89.8783,
    region: "Midwest",
    state: "Wisconsin",
    country: "United States",
    best_months: "May through October",
    nearest_airports: "Central Wisconsin Airport (CWA) - 1 hour, Milwaukee Mitchell International Airport (MKE) - 3 hours",
    weather_info: "Continental climate with warm summers and cold winters. Summer temperatures range from 60-85°F. Spring and fall can be unpredictable but often offer excellent golf conditions."
  },
  {
    name: "Maui",
    description: "Tropical paradise featuring world-class golf courses with breathtaking ocean views, volcanic landscapes, and year-round perfect weather. Home to several championship courses designed by legendary architects.",
    latitude: 20.8783,
    longitude: -156.6825,
    region: "Hawaii",
    state: "Hawaii",
    country: "United States",
    best_months: "Year-round, with December through March being peak season",
    nearest_airports: "Kahului Airport (OGG) - various distances to courses",
    weather_info: "Tropical climate with temperatures consistently between 70-85°F year-round. Trade winds provide natural cooling. Occasional brief showers, with slightly more rain in winter months."
  },
  {
    name: "Arcadia Bluffs",
    description: "Perched on the bluffs of Lake Michigan, this destination offers dramatic clifftop golf with sweeping views of the Great Lake. Known for its links-style layout and challenging conditions.",
    latitude: 44.4097,
    longitude: -86.2339,
    region: "Midwest",
    state: "Michigan",
    country: "United States",
    best_months: "June through September",
    nearest_airports: "Cherry Capital Airport (TVC) - 1.5 hours, Gerald R. Ford International Airport (GRR) - 3 hours",
    weather_info: "Summer temperatures range from 60-80°F with moderate humidity. Spring and fall can be cool with variable conditions. Lake effect weather can bring sudden changes."
  },
  {
    name: "Lake Tahoe",
    description: "High-altitude golf destination surrounded by the Sierra Nevada mountains, offering spectacular views and challenging mountain courses. Combines world-class golf with amazing outdoor recreation opportunities.",
    latitude: 39.0968,
    longitude: -120.0324,
    region: "Sierra Nevada",
    state: "California/Nevada",
    country: "United States",
    best_months: "June through September",
    nearest_airports: "Reno-Tahoe International Airport (RNO) - 1 hour, Sacramento International Airport (SMF) - 2 hours",
    weather_info: "Alpine climate with warm, dry summers and snowy winters. Summer temperatures range from 45-80°F. Thin air at elevation affects ball flight. Afternoon thunderstorms possible in summer."
  },
  {
    name: "Las Vegas",
    description: "Desert golf paradise featuring numerous high-end resort courses and private clubs. Offers year-round golf with dramatic desert landscapes, mountain backdrops, and proximity to world-class entertainment.",
    latitude: 36.1699,
    longitude: -115.1398,
    region: "Southwest",
    state: "Nevada",
    country: "United States",
    best_months: "October through April",
    nearest_airports: "Harry Reid International Airport (LAS) - various distances to courses",
    weather_info: "Desert climate with hot summers (95-105°F) and mild winters (60-70°F). Very low humidity and minimal rainfall. Best conditions in spring and fall. Summer golf typically starts very early morning."
  }
]

puts "Creating original locations..."
original_locations.each do |location_data|
  courses_data = location_data.delete(:courses_attributes)
  location = Location.create!(location_data)
  
  courses_data.each do |course_data|
    reviews_data = course_data.delete(:reviews_attributes)
    course = Course.create!(course_data)
    LocationCourse.create!(location: location, course: course)
    
    reviews_data&.each do |review_data|
      Review.create!(review_data.merge(course: course))
    end
  end
  
  puts "Created #{location.name} with #{location.courses.count} courses and #{location.reviews.count} reviews"
end

puts "Creating Minnesota locations..."
minnesota_locations.each do |location_data|
  courses_data = location_data.delete(:courses_attributes)
  location = Location.create!(location_data)
  
  courses_data.each do |course_data|
    course = Course.create!(course_data)
    LocationCourse.create!(location: location, course: course)
  end
  
  puts "Created #{location.name} with #{location.courses.count} courses"
end

puts "Creating Myrtle Beach locations and courses..."
myrtle_beach_locations.each do |location_data|
  courses_data = location_data.delete(:courses_attributes)
  location = Location.create!(location_data)
  
  courses_data.each do |course_data|
    reviews_data = course_data.delete(:reviews_attributes)
    course = Course.create!(course_data)
    LocationCourse.create!(location: location, course: course)
    
    reviews_data&.each do |review_data|
      Review.create!(review_data.merge(course: course))
    end
  end
  
  puts "Created #{location.name} with #{location.courses.count} courses and #{location.reviews.count} reviews"
end

# Add the new locations to the database
new_locations.each do |location_data|
  Location.create!(location_data)
  puts "Created location: #{location_data[:name]}"
end

puts "Seeding completed!"