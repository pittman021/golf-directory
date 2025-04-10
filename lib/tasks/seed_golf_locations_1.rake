namespace :db do
  namespace :seed do
    desc "Seed top golf destinations"
    task top_golf_locations: :environment do
  
      bandon_dunes = Location.create!(
        name: "Bandon Dunes",
        description: "Bandon Dunes Golf Resort in Oregon is a legendary destination with five authentic links courses on the dramatic Pacific coastline.",
        latitude: 43.1896,
        longitude: -124.4081,
        region: "Pacific Northwest",
        state: "OR",
        country: "USA",
        best_months: "May,June,July,August,September",
        nearest_airports: "Southwest Oregon Regional Airport (OTH) - 30 miles, Eugene Airport (EUG) - 150 miles",
        weather_info: "Mild summers (60–70°F), frequent coastal wind and fog, limited rainfall.",
        avg_green_fee: 370,
        avg_lodging_cost_per_night: 250,
        estimated_trip_cost: 2500,
        tags: ["resort", "links", "coastal"],
        summary: "An iconic links golf experience with rugged coastal beauty. Best for serious golfers; limited nightlife and remote location."
      )
  
      pinehurst = Location.create!(
        name: "Pinehurst",
        description: "Pinehurst in North Carolina is a historic golf mecca with nine distinct courses, including the world-renowned Pinehurst No. 2.",
        latitude: 35.1954,
        longitude: -79.4696,
        region: "Southeast",
        state: "North Carolina",
        country: "USA",
        best_months: "March,April,May,September,October",
        nearest_airports: "Raleigh-Durham International Airport (RDU) - 74 miles",
        weather_info: "Spring/fall highs in 65–75°F range. Summers are hot and humid.",
        avg_green_fee: 350,
        avg_lodging_cost_per_night: 300,
        estimated_trip_cost: 2800,
        tags: ["resort", "historic", "multiple courses"],
        summary: "A rich and traditional golf setting with historic roots. Ideal for golf purists, but lacks modern nightlife."
      )

      kiawah_island_sc = Location.create!(
        name: "Kiawah Island",
        description: "Kiawah Island, located near Charleston, South Carolina, offers five championship courses, including the renowned Ocean Course.",
        latitude: 32.6088,
        longitude: -80.0846,
        region: "Southeast",
        state: "South Carolina",
        country: "USA",
        best_months: "March,April,May,September,October",
        nearest_airports: "Charleston International Airport (CHS) - 33 miles",
        weather_info: "Mild winters (50–60°F), warm summers (80–90°F), occasional coastal breezes.",
        avg_green_fee: 350,
        avg_lodging_cost_per_night: 300,
        estimated_trip_cost: 2200,
        tags: ["resort", "coastal", "championship courses"],
        summary: "A luxurious coastal retreat offering world-class golf and amenities. Ideal for those seeking both challenge and relaxation."
      )

      palm_springs_ca = Location.create!(
        name: "Palm Springs / La Quinta",
        description: "The Palm Springs and La Quinta area in California boasts over 100 golf courses set against a stunning desert backdrop.",
        latitude: 33.8303,
        longitude: -116.5453,
        region: "West",
        state: "California",
        country: "USA",
        best_months: "October,November,March,April",
        nearest_airports: "Palm Springs International Airport (PSP) - 3 miles",
        weather_info: "Hot summers (100–110°F), mild winters (60–70°F), low humidity.",
        avg_green_fee: 150,
        avg_lodging_cost_per_night: 200,
        estimated_trip_cost: 1800,
        tags: ["desert", "variety", "resort"],
        summary: "A premier desert golf destination with a wide variety of courses and luxurious resorts. Best visited in cooler months."
      )

      hilton_head_sc = Location.create!(
        name: "Hilton Head Island",
        description: "Hilton Head Island, South Carolina, features over 20 championship golf courses designed by renowned architects.",
        latitude: 32.2163,
        longitude: -80.7526,
        region: "Southeast",
        state: "South Carolina",
        country: "USA",
        best_months: "March,April,May,September,October",
        nearest_airports: "Savannah/Hilton Head International Airport (SAV) - 45 miles",
        weather_info: "Mild winters (50–60°F), warm summers (80–90°F), occasional humidity.",
        avg_green_fee: 180,
        avg_lodging_cost_per_night: 220,
        estimated_trip_cost: 2000,
        tags: ["coastal", "resort", "variety"],
        summary: "A scenic island destination offering a mix of public and private courses, complemented by beautiful beaches and upscale amenities."
      )

      orlando_fl = Location.create!(
            name: "Orlando",
            description: "Orlando, Florida, is a golfer's paradise with over 170 courses ranging from public to championship-level, all within close proximity to world-famous attractions.",
            latitude: 28.5383,
            longitude: -81.3792,
            region: "Southeast",
            state: "Florida",
            country: "USA",
            best_months: "October,November,March,April",
            nearest_airports: "Orlando International Airport (MCO) - 13 miles",
            weather_info: "Hot summers (90–95°F), mild winters (60–70°F), occasional rain.",
            avg_green_fee: 120,
            avg_lodging_cost_per_night: 150,
            estimated_trip_cost: 1600,
            tags: ["variety", "family-friendly", "resort"],
            summary: "A diverse golf destination with courses suitable for all skill levels, complemented by numerous entertainment options."
          )

          # 7. San Diego, California
san_diego_ca = Location.create!(
  name: "San Diego",
  description: "San Diego, California, offers more than 70 golf courses with a mix of ocean views, inland hills, and world-famous Torrey Pines.",
  latitude: 32.7157,
  longitude: -117.1611,
  region: "West",
  state: "California",
  country: "USA",
  best_months: "March,April,May,September,October,November",
  nearest_airports: "San Diego International Airport (SAN) - 3 miles",
  weather_info: "Mild, dry weather year-round (60–75°F), low humidity, little rainfall.",
  avg_green_fee: 170,
  avg_lodging_cost_per_night: 230,
  estimated_trip_cost: 1900,
  tags: ["coastal", "public courses", "year-round"],
  summary: "Consistently perfect weather and public-friendly options make San Diego a go-to for casual and serious golfers alike."
)

# 8. Naples, Florida
naples_fl = Location.create!(
  name: "Naples",
  description: "Naples, Florida, is known for upscale golf and lifestyle, with more than 90 courses, many with public access.",
  latitude: 26.1420,
  longitude: -81.7948,
  region: "Southeast",
  state: "Florida",
  country: "USA",
  best_months: "January,February,March,April,November,December",
  nearest_airports: "Southwest Florida International Airport (RSW) - 35 miles",
  weather_info: "Warm winters (70–80°F), hot summers (90–95°F), high humidity, rainy summers.",
  avg_green_fee: 180,
  avg_lodging_cost_per_night: 280,
  estimated_trip_cost: 2200,
  tags: ["luxury", "coastal", "snowbird"],
  summary: "A high-end golf destination with great winter weather and polished amenities. Best for a laid-back, upscale trip."
)

# 9. Boca Raton / West Palm Beach, Florida
boca_west_palm_fl = Location.create!(
  name: "Boca Raton / West Palm Beach",
  description: "Boca Raton and West Palm Beach offer a strong mix of resort, private, and public golf across Florida's Gold Coast.",
  latitude: 26.3587,
  longitude: -80.0831,
  region: "Southeast",
  state: "Florida",
  country: "USA",
  best_months: "January,February,March,April,November,December",
  nearest_airports: "Palm Beach International Airport (PBI) - 4 miles, Fort Lauderdale-Hollywood International Airport (FLL) - 25 miles",
  weather_info: "Warm year-round (70–90°F), humid summers, mild dry winters.",
  avg_green_fee: 160,
  avg_lodging_cost_per_night: 250,
  estimated_trip_cost: 2100,
  tags: ["coastal", "resort", "variety"],
  summary: "A year-round Florida golf hub with beach access and a blend of affordable and luxury options. Popular with groups and retirees."
)

# 10. Lake Tahoe (CA/NV)
lake_tahoe = Location.create!(
  name: "Lake Tahoe",
  description: "Lake Tahoe straddles California and Nevada, offering stunning high-altitude golf with mountain backdrops and nearby casino resorts.",
  latitude: 39.0968,
  longitude: -120.0324,
  region: "West",
  state: "California",
  country: "USA",
  best_months: "June,July,August,September",
  nearest_airports: "Reno-Tahoe International Airport (RNO) - 55 miles, Sacramento International Airport (SMF) - 120 miles",
  weather_info: "Cool dry summers (70–80°F), cold winters, high elevation.",
  avg_green_fee: 180,
  avg_lodging_cost_per_night: 200,
  estimated_trip_cost: 2000,
  tags: ["mountain", "summer only", "casino"],
  summary: "Summer-only destination with scenic views, elevation changes, and nightlife. Great for group trips with variety."
)


    end
  end
end
  