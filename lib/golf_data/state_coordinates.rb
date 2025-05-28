module GolfData
  StateCoordinates = {
    "Alabama" => [
      { lat: 32.8067, lng: -86.7911 },  # Montgomery (state center)
      { lat: 33.5207, lng: -86.8025 },  # Birmingham
      { lat: 34.7304, lng: -86.5861 },  # Huntsville
      { lat: 30.6954, lng: -88.0399 },  # Mobile
      { lat: 32.4609, lng: -85.0007 },  # Auburn/Opelika
      { lat: 33.2148, lng: -87.5692 },  # Tuscaloosa
      { lat: 34.6059, lng: -86.9833 },  # Decatur
      { lat: 32.3668, lng: -86.2999 }   # Prattville
    ],
    "Alaska" => [
      { lat: 61.2181, lng: -149.9003 }, # Anchorage
      { lat: 64.8378, lng: -147.7164 }, # Fairbanks
      { lat: 58.3019, lng: -134.4197 }, # Juneau
      { lat: 64.2008, lng: -149.4937 }, # State center
      { lat: 55.3422, lng: -131.6461 }, # Ketchikan
      { lat: 57.0531, lng: -135.3300 }  # Sitka
    ],
    "Arizona" => [
      { lat: 33.4484, lng: -112.0740 }, # Phoenix
      { lat: 32.2226, lng: -110.9747 }, # Tucson
      { lat: 35.1983, lng: -111.6513 }, # Flagstaff
      { lat: 33.3528, lng: -111.7890 }, # Scottsdale
      { lat: 34.5394, lng: -114.1427 }, # Lake Havasu
      { lat: 34.0489, lng: -111.0937 }, # State center
      { lat: 32.7016, lng: -114.6276 }, # Yuma
      { lat: 33.3692, lng: -112.4580 }, # Glendale
      { lat: 33.4152, lng: -111.8315 }  # Tempe
    ],
    "Arkansas" => [
      { lat: 34.7465, lng: -92.2896 },  # Little Rock
      { lat: 36.0822, lng: -94.1719 },  # Fayetteville
      { lat: 35.8417, lng: -90.7043 },  # Jonesboro
      { lat: 33.2148, lng: -93.1137 },  # Texarkana
      { lat: 34.9697, lng: -92.3731 },  # State center
      { lat: 35.3859, lng: -94.3985 },  # Fort Smith
      { lat: 34.5037, lng: -92.4426 },  # North Little Rock
      { lat: 35.2431, lng: -92.4426 }   # Conway
    ],
    "California" => [
      { lat: 36.7783, lng: -119.4179 },  # Central CA (Fresno)
      { lat: 34.0522, lng: -118.2437 },  # Los Angeles
      { lat: 33.8121, lng: -117.9190 },  # Anaheim/Orange County
      { lat: 32.7157, lng: -117.1611 },  # San Diego
      { lat: 36.6002, lng: -121.8947 },  # Monterey/Carmel
      { lat: 37.7749, lng: -122.4194 },  # San Francisco
      { lat: 38.5816, lng: -121.4944 },  # Sacramento
      { lat: 34.9592, lng: -116.4194 },  # Palm Springs/Desert
      { lat: 34.4208, lng: -119.6982 },  # Santa Barbara
      { lat: 35.3733, lng: -119.0187 },  # Bakersfield
      { lat: 37.3382, lng: -121.8863 },  # San Jose/Silicon Valley
      { lat: 33.1959, lng: -117.3795 },  # North County San Diego
      { lat: 38.2904, lng: -122.4580 },  # Napa Valley
      { lat: 39.1612, lng: -121.6077 },  # Chico/Northern Central Valley
      { lat: 35.6870, lng: -121.3370 },  # San Luis Obispo
      { lat: 40.5865, lng: -122.3917 },  # Redding
      { lat: 33.6803, lng: -116.2436 },  # Coachella Valley
      { lat: 34.1425, lng: -117.2297 },  # San Bernardino
      { lat: 33.9425, lng: -117.2297 },  # Riverside
      { lat: 37.4419, lng: -122.1430 }   # Palo Alto/Peninsula
    ],
    "Colorado" => [
      { lat: 39.7392, lng: -104.9903 },  # Denver
      { lat: 38.8339, lng: -104.8214 },  # Colorado Springs
      { lat: 40.5853, lng: -105.0844 },  # Boulder
      { lat: 39.5501, lng: -105.7821 },  # State center
      { lat: 37.2753, lng: -107.8801 },  # Durango
      { lat: 39.6403, lng: -106.3742 },  # Vail/Aspen area
      { lat: 40.4850, lng: -106.8317 },  # Steamboat Springs
      { lat: 39.0639, lng: -108.5506 },  # Grand Junction
      { lat: 40.2677, lng: -104.6070 }   # Greeley
    ],
    "Connecticut" => [
      { lat: 41.7658, lng: -72.6734 },   # Hartford
      { lat: 41.3083, lng: -72.9279 },   # New Haven
      { lat: 41.0534, lng: -73.5387 },   # Stamford
      { lat: 41.6032, lng: -73.0877 },   # State center
      { lat: 41.2033, lng: -73.2068 },   # Waterbury
      { lat: 41.3712, lng: -72.1006 }    # New London
    ],
    "Delaware" => [
      { lat: 39.7391, lng: -75.5398 },   # Wilmington
      { lat: 39.1612, lng: -75.5264 },   # Dover
      { lat: 38.6201, lng: -75.0552 },   # Rehoboth Beach
      { lat: 38.9108, lng: -75.5277 }    # State center
    ],
    "Florida" => [
      { lat: 27.9944, lng: -81.7603 },   # State center
      { lat: 25.7617, lng: -80.1918 },   # Miami
      { lat: 28.5383, lng: -81.3792 },   # Orlando
      { lat: 30.3322, lng: -81.6557 },   # Jacksonville
      { lat: 26.6406, lng: -81.8723 },   # Fort Myers/Naples
      { lat: 27.9506, lng: -82.4572 },   # Tampa
      { lat: 26.1224, lng: -80.1373 },   # Fort Lauderdale
      { lat: 30.4518, lng: -84.2807 },   # Tallahassee
      { lat: 29.6516, lng: -82.3248 },   # Gainesville
      { lat: 24.5557, lng: -81.7826 },   # Key West
      { lat: 28.0836, lng: -80.6081 },   # Melbourne/Space Coast
      { lat: 27.3364, lng: -82.5307 },   # Sarasota
      { lat: 30.1588, lng: -85.6602 },   # Panama City
      { lat: 26.7153, lng: -80.0534 },   # West Palm Beach
      { lat: 28.8028, lng: -81.9481 },   # Leesburg/The Villages
      { lat: 29.1816, lng: -82.1401 },   # Ocala
      { lat: 27.7676, lng: -82.6404 },   # St. Petersburg
      { lat: 29.9012, lng: -81.3124 }    # St. Augustine
    ],
    "Georgia" => [
      { lat: 32.1656, lng: -82.9001 },   # State center
      { lat: 33.7490, lng: -84.3880 },   # Atlanta
      { lat: 31.1499, lng: -81.4915 },   # Brunswick/St. Simons
      { lat: 32.0809, lng: -81.0912 },   # Savannah
      { lat: 32.4609, lng: -83.6324 },   # Macon
      { lat: 31.5804, lng: -84.1557 },   # Albany
      { lat: 34.2979, lng: -85.0077 },   # Rome
      { lat: 33.9519, lng: -83.3576 },   # Athens
      { lat: 33.2515, lng: -83.8287 },   # Milledgeville
      { lat: 31.2077, lng: -83.2312 },   # Valdosta
      { lat: 34.0754, lng: -84.2941 }    # Gainesville
    ],
    "Hawaii" => [
      { lat: 21.3099, lng: -157.8581 },  # Honolulu (Oahu)
      { lat: 20.7984, lng: -156.3319 },  # Maui
      { lat: 19.8968, lng: -155.5828 },  # Big Island (Hilo)
      { lat: 19.7297, lng: -155.0890 },  # Big Island (Kona)
      { lat: 22.0964, lng: -159.5261 },  # Kauai
      { lat: 21.4389, lng: -158.0001 },  # Oahu North Shore
      { lat: 20.8893, lng: -156.4729 }   # Maui Upcountry
    ],
    "Idaho" => [
      { lat: 43.6150, lng: -116.2023 },  # Boise
      { lat: 47.6587, lng: -117.4260 },  # Coeur d'Alene
      { lat: 43.4642, lng: -112.0362 },  # Idaho Falls
      { lat: 42.5584, lng: -114.4619 },  # Twin Falls
      { lat: 44.0682, lng: -114.742 },   # State center
      { lat: 46.4165, lng: -116.9665 },  # Lewiston
      { lat: 44.0581, lng: -115.3153 },  # McCall
      { lat: 42.8713, lng: -112.4455 }   # Pocatello
    ],
    "Illinois" => [
      { lat: 41.8781, lng: -87.6298 },   # Chicago
      { lat: 39.7817, lng: -89.6501 },   # Springfield
      { lat: 40.1164, lng: -88.2434 },   # Champaign-Urbana
      { lat: 41.5067, lng: -90.5151 },   # Rock Island/Quad Cities
      { lat: 40.6331, lng: -89.3985 },   # State center
      { lat: 42.2711, lng: -89.0940 },   # Rockford
      { lat: 40.6936, lng: -89.5889 },   # Peoria
      { lat: 38.6270, lng: -90.1994 }    # East St. Louis area
    ],
    "Indiana" => [
      { lat: 39.7684, lng: -86.1581 },   # Indianapolis
      { lat: 41.5868, lng: -87.3467 },   # Gary/Northwest Indiana
      { lat: 39.1612, lng: -87.3348 },   # Terre Haute
      { lat: 41.0814, lng: -85.1394 },   # Fort Wayne
      { lat: 38.0406, lng: -87.5342 },   # Evansville
      { lat: 40.2672, lng: -86.1349 },   # State center
      { lat: 40.4237, lng: -86.9212 },   # Lafayette
      { lat: 39.1637, lng: -85.8839 }    # Bloomington
    ],
    "Iowa" => [
      { lat: 41.5868, lng: -93.6250 },   # Des Moines
      { lat: 41.6611, lng: -91.5302 },   # Iowa City
      { lat: 42.5584, lng: -92.6488 },   # Waterloo/Cedar Falls
      { lat: 41.2619, lng: -95.8608 },   # Council Bluffs
      { lat: 41.8780, lng: -93.0977 },   # State center
      { lat: 42.5047, lng: -94.1723 },   # Fort Dodge
      { lat: 41.5236, lng: -91.1404 },   # Cedar Rapids
      { lat: 42.4999, lng: -96.4003 }    # Sioux City
    ],
    "Kansas" => [
      { lat: 39.0473, lng: -95.6890 },   # Topeka
      { lat: 39.1142, lng: -94.6275 },   # Kansas City area
      { lat: 37.6872, lng: -97.3301 },   # Wichita
      { lat: 39.0119, lng: -98.4842 },   # State center
      { lat: 38.9517, lng: -95.2353 },   # Lawrence
      { lat: 37.0717, lng: -100.9185 },  # Dodge City
      { lat: 39.3744, lng: -101.0499 }   # Goodland
    ],
    "Kentucky" => [
      { lat: 38.2009, lng: -84.8733 },   # Frankfort
      { lat: 38.2527, lng: -85.7585 },   # Louisville
      { lat: 37.0778, lng: -84.5037 },   # Somerset/Lake Cumberland
      { lat: 36.7409, lng: -87.4917 },   # Bowling Green
      { lat: 37.8393, lng: -84.2700 },   # State center
      { lat: 38.0406, lng: -84.5037 },   # Lexington
      { lat: 36.8403, lng: -83.9207 },   # Corbin
      { lat: 37.1617, lng: -88.6181 }    # Paducah
    ],
    "Louisiana" => [
      { lat: 29.9511, lng: -90.0715 },   # New Orleans
      { lat: 30.4515, lng: -91.1871 },   # Baton Rouge
      { lat: 32.5252, lng: -93.7502 },   # Shreveport
      { lat: 30.2241, lng: -92.0198 },   # Lafayette
      { lat: 30.9843, lng: -91.9623 },   # State center
      { lat: 32.5093, lng: -92.1193 },   # Monroe
      { lat: 30.2266, lng: -93.2174 },   # Lake Charles
      { lat: 29.3013, lng: -89.7645 }    # Houma
    ],
    "Maine" => [
      { lat: 43.6591, lng: -70.2568 },   # Portland
      { lat: 44.3106, lng: -69.7795 },   # Augusta
      { lat: 46.8059, lng: -68.7778 },   # Presque Isle
      { lat: 44.4759, lng: -69.2203 },   # Waterville
      { lat: 45.2538, lng: -69.4455 },   # State center
      { lat: 44.8016, lng: -68.7712 },   # Bangor
      { lat: 44.5588, lng: -69.6581 },   # Skowhegan
      { lat: 43.9108, lng: -70.2568 }    # Biddeford
    ],
    "Maryland" => [
      { lat: 39.2904, lng: -76.6122 },   # Baltimore
      { lat: 38.9072, lng: -77.0369 },   # Washington DC area
      { lat: 39.0458, lng: -76.6413 },   # State center
      { lat: 38.3107, lng: -75.8803 },   # Salisbury/Eastern Shore
      { lat: 39.6403, lng: -77.7200 },   # Hagerstown
      { lat: 38.2904, lng: -76.5422 }    # Annapolis
    ],
    "Massachusetts" => [
      { lat: 42.3601, lng: -71.0589 },   # Boston
      { lat: 42.1015, lng: -72.5898 },   # Springfield
      { lat: 41.7003, lng: -70.2962 },   # Cape Cod
      { lat: 42.2626, lng: -71.8023 },   # Worcester
      { lat: 42.4072, lng: -71.3824 },   # State center
      { lat: 42.5195, lng: -70.8967 },   # Lowell
      { lat: 41.5101, lng: -70.9340 },   # New Bedford
      { lat: 42.7762, lng: -71.0773 }    # Lowell
    ],
    "Michigan" => [
      { lat: 42.3314, lng: -84.5467 },   # Lansing
      { lat: 42.3314, lng: -83.0458 },   # Detroit
      { lat: 42.9634, lng: -85.6681 },   # Grand Rapids
      { lat: 46.5197, lng: -84.3476 },   # Sault Ste. Marie
      { lat: 45.0218, lng: -84.6882 },   # Gaylord/Northern Michigan
      { lat: 44.3148, lng: -85.6024 },   # State center
      { lat: 43.0642, lng: -87.9073 },   # Kalamazoo
      { lat: 46.5563, lng: -87.3954 },   # Marquette
      { lat: 42.2339, lng: -84.4008 },   # Jackson
      { lat: 43.6532, lng: -84.2807 }    # Bay City
    ],
    "Minnesota" => [
      { lat: 44.9537, lng: -93.0900 },   # Minneapolis/St. Paul
      { lat: 46.7867, lng: -92.1005 },   # Duluth
      { lat: 44.0121, lng: -92.4802 },   # Rochester
      { lat: 45.5579, lng: -94.6859 },   # St. Cloud
      { lat: 46.7296, lng: -94.6859 },   # State center
      { lat: 47.9211, lng: -91.3470 },   # International Falls
      { lat: 44.0154, lng: -93.4665 },   # Mankato
      { lat: 46.3605, lng: -94.2008 }    # Brainerd
    ],
    "Mississippi" => [
      { lat: 32.2988, lng: -90.1848 },   # Jackson
      { lat: 33.4951, lng: -88.8184 },   # Tupelo
      { lat: 30.3969, lng: -89.0928 },   # Biloxi/Gulf Coast
      { lat: 33.4735, lng: -90.1758 },   # Greenwood
      { lat: 32.3547, lng: -89.3985 },   # State center
      { lat: 34.2581, lng: -88.7137 },   # Oxford
      { lat: 31.3271, lng: -89.2903 },   # Hattiesburg
      { lat: 33.5057, lng: -90.1848 }    # Greenville
    ],
    "Missouri" => [
      { lat: 38.5767, lng: -92.1735 },   # Jefferson City
      { lat: 39.0997, lng: -94.5786 },   # Kansas City
      { lat: 38.6270, lng: -90.1994 },   # St. Louis
      { lat: 37.2153, lng: -93.2982 },   # Springfield
      { lat: 37.9643, lng: -91.8318 },   # State center
      { lat: 39.7391, lng: -91.3762 },   # Hannibal
      { lat: 36.6073, lng: -93.2982 },   # Branson
      { lat: 37.0842, lng: -94.5133 }    # Joplin
    ],
    "Montana" => [
      { lat: 46.5197, lng: -112.0362 },  # Helena
      { lat: 45.7833, lng: -108.5007 },  # Billings
      { lat: 47.0527, lng: -114.0823 },  # Missoula
      { lat: 48.2088, lng: -114.0823 },  # Kalispell
      { lat: 46.8797, lng: -110.3626 },  # State center
      { lat: 47.5053, lng: -111.3008 },  # Great Falls
      { lat: 45.6770, lng: -111.0429 },  # Bozeman
      { lat: 48.1476, lng: -104.7129 }   # Glendive
    ],
    "Nebraska" => [
      { lat: 40.8136, lng: -96.7026 },   # Lincoln
      { lat: 41.2565, lng: -95.9345 },   # Omaha
      { lat: 40.9248, lng: -98.3434 },   # Grand Island
      { lat: 41.4925, lng: -99.9018 },   # State center
      { lat: 41.1400, lng: -100.7696 },  # North Platte
      { lat: 42.0308, lng: -102.9713 },  # Scottsbluff
      { lat: 40.5008, lng: -99.0817 }    # Kearney
    ],
    "Nevada" => [
      { lat: 36.1699, lng: -115.1398 },  # Las Vegas
      { lat: 39.1638, lng: -119.7674 },  # Reno
      { lat: 39.5296, lng: -116.9325 },  # Elko
      { lat: 38.8026, lng: -116.4194 },  # State center
      { lat: 39.5349, lng: -118.7772 },  # Fallon
      { lat: 36.2085, lng: -115.2739 },  # Henderson
      { lat: 40.7394, lng: -116.1956 }   # Winnemucca
    ],
    "New Hampshire" => [
      { lat: 43.2081, lng: -71.5376 },   # Concord
      { lat: 42.9956, lng: -71.4548 },   # Manchester
      { lat: 44.2619, lng: -71.5376 },   # North Conway
      { lat: 43.1939, lng: -71.5724 },   # State center
      { lat: 43.0642, lng: -70.7636 },   # Portsmouth
      { lat: 44.4889, lng: -71.1525 }    # Berlin
    ],
    "New Jersey" => [
      { lat: 40.2206, lng: -74.7563 },   # Trenton
      { lat: 40.7282, lng: -74.0776 },   # Newark/NYC area
      { lat: 39.3643, lng: -74.4229 },   # Atlantic City
      { lat: 40.0583, lng: -74.4057 },   # State center
      { lat: 40.9176, lng: -74.1718 },   # Paterson
      { lat: 39.7391, lng: -75.1094 },   # Camden
      { lat: 40.0583, lng: -74.7563 }    # Princeton
    ],
    "New Mexico" => [
      { lat: 35.6870, lng: -105.9378 },  # Santa Fe
      { lat: 35.0844, lng: -106.6504 },  # Albuquerque
      { lat: 32.3199, lng: -106.7637 },  # Las Cruces
      { lat: 36.7201, lng: -108.2187 },  # Farmington
      { lat: 34.5199, lng: -105.8701 },  # State center
      { lat: 32.9003, lng: -103.2310 },  # Roswell
      { lat: 35.6603, lng: -105.9644 },  # Los Alamos
      { lat: 36.4103, lng: -105.5731 }   # Taos
    ],
    "New York" => [
      { lat: 43.0000, lng: -75.0000 },   # State center
      { lat: 40.7128, lng: -74.0060 },   # NYC metro
      { lat: 42.8864, lng: -78.8784 },   # Buffalo
      { lat: 43.1566, lng: -77.6088 },   # Rochester
      { lat: 42.6526, lng: -73.7562 },   # Albany
      { lat: 43.0481, lng: -76.1474 },   # Syracuse
      { lat: 42.0987, lng: -75.9180 },   # Binghamton
      { lat: 44.6939, lng: -73.4454 },   # Plattsburgh
      { lat: 40.9176, lng: -72.7237 },   # Long Island
      { lat: 42.4430, lng: -76.5019 },   # Ithaca
      { lat: 43.0962, lng: -75.2330 },   # Utica
      { lat: 41.7003, lng: -74.0118 }    # Middletown
    ],
    "North Carolina" => [
      { lat: 35.7596, lng: -79.0193 },   # State center
      { lat: 35.2271, lng: -80.8431 },   # Charlotte
      { lat: 35.7796, lng: -78.6382 },   # Raleigh
      { lat: 34.2257, lng: -77.9447 },   # Wilmington
      { lat: 35.5951, lng: -82.5515 },   # Asheville
      { lat: 36.0726, lng: -79.7920 },   # Greensboro
      { lat: 35.2220, lng: -81.4956 },   # Gastonia
      { lat: 35.0527, lng: -78.8784 },   # Fayetteville
      { lat: 36.1023, lng: -80.2442 },   # Winston-Salem
      { lat: 35.9132, lng: -79.0558 },   # Durham
      { lat: 34.2104, lng: -78.0072 }    # Jacksonville
    ],
    "North Dakota" => [
      { lat: 46.8083, lng: -100.7837 },  # Bismarck
      { lat: 46.8772, lng: -96.7898 },   # Fargo
      { lat: 48.2330, lng: -101.2951 },  # Minot
      { lat: 47.5515, lng: -101.002 },   # State center
      { lat: 48.2772, lng: -103.2084 },  # Williston
      { lat: 47.9253, lng: -97.0329 }    # Grand Forks
    ],
    "Ohio" => [
      { lat: 39.9612, lng: -82.9988 },   # Columbus
      { lat: 41.4993, lng: -81.6944 },   # Cleveland
      { lat: 39.1031, lng: -84.5120 },   # Cincinnati
      { lat: 41.0534, lng: -81.1900 },   # Akron
      { lat: 39.7589, lng: -84.1916 },   # Dayton
      { lat: 40.4173, lng: -82.9071 },   # State center
      { lat: 41.6528, lng: -83.5379 },   # Toledo
      { lat: 40.7989, lng: -81.3781 },   # Canton
      { lat: 39.3292, lng: -82.1013 }    # Chillicothe
    ],
    "Oklahoma" => [
      { lat: 35.4676, lng: -97.5164 },   # Oklahoma City
      { lat: 36.1540, lng: -95.9928 },   # Tulsa
      { lat: 35.2131, lng: -97.4395 },   # Norman
      { lat: 34.6037, lng: -98.3959 },   # Lawton
      { lat: 36.9342, lng: -94.8758 },   # Bartlesville
      { lat: 35.0078, lng: -97.0929 },   # Shawnee
      { lat: 36.7279, lng: -97.0929 }    # Stillwater
    ],
    "Oregon" => [
      { lat: 45.5152, lng: -122.6784 },  # Portland
      { lat: 44.0521, lng: -123.0868 },  # Salem
      { lat: 44.0582, lng: -121.3153 },  # Bend
      { lat: 42.3265, lng: -122.8756 },  # Medford
      { lat: 43.8041, lng: -120.5542 },  # State center
      { lat: 44.0521, lng: -123.0868 },  # Corvallis
      { lat: 45.3311, lng: -121.7113 },  # Hood River
      { lat: 42.1918, lng: -124.2026 }   # Coos Bay
    ],
    "Pennsylvania" => [
      { lat: 39.9526, lng: -75.1652 },   # Philadelphia
      { lat: 40.4406, lng: -79.9959 },   # Pittsburgh
      { lat: 40.2732, lng: -76.8839 },   # Harrisburg
      { lat: 41.2033, lng: -77.1945 },   # State center
      { lat: 40.6259, lng: -75.3721 },   # Allentown
      { lat: 41.4090, lng: -75.6624 },   # Scranton
      { lat: 40.2677, lng: -80.2151 },   # Washington
      { lat: 42.1292, lng: -80.0851 },   # Erie
      { lat: 40.3573, lng: -76.3054 }    # Lancaster
    ],
    "Rhode Island" => [
      { lat: 41.8240, lng: -71.4128 },   # Providence
      { lat: 41.4901, lng: -71.3128 },   # Newport
      { lat: 41.5801, lng: -71.4774 },   # State center
      { lat: 41.3712, lng: -71.7581 }    # Westerly
    ],
    "South Carolina" => [
      { lat: 34.0000, lng: -81.0348 },   # Columbia
      { lat: 32.7765, lng: -79.9311 },   # Charleston
      { lat: 34.8526, lng: -82.3940 },   # Greenville
      { lat: 33.6891, lng: -78.8867 },   # Myrtle Beach
      { lat: 33.8361, lng: -81.1637 },   # State center
      { lat: 34.9296, lng: -81.9498 },   # Spartanburg
      { lat: 33.3734, lng: -82.1179 },   # Aiken
      { lat: 32.4609, lng: -80.3348 }    # Beaufort
    ],
    "South Dakota" => [
      { lat: 44.2998, lng: -100.3510 },  # Pierre
      { lat: 43.5460, lng: -96.7313 },   # Sioux Falls
      { lat: 44.0805, lng: -103.2310 },  # Rapid City
      { lat: 43.9695, lng: -99.9018 },   # State center
      { lat: 45.4706, lng: -98.4842 },   # Aberdeen
      { lat: 44.3683, lng: -96.8103 }    # Brookings
    ],
    "Tennessee" => [
      { lat: 36.1627, lng: -86.7816 },   # Nashville
      { lat: 35.1495, lng: -90.0490 },   # Memphis
      { lat: 35.9606, lng: -83.9207 },   # Knoxville
      { lat: 35.0456, lng: -85.3097 },   # Chattanooga
      { lat: 35.5175, lng: -86.5804 },   # State center
      { lat: 36.5431, lng: -87.3595 },   # Clarksville
      { lat: 36.1581, lng: -86.7816 },   # Franklin
      { lat: 35.2271, lng: -89.9287 }    # Jackson
    ],
    "Texas" => [
      { lat: 31.9686, lng: -99.9018 },   # Central TX
      { lat: 29.7604, lng: -95.3698 },   # Houston
      { lat: 30.2672, lng: -97.7431 },   # Austin
      { lat: 32.7767, lng: -96.7970 },   # Dallas
      { lat: 29.4241, lng: -98.4936 },   # San Antonio
      { lat: 33.5779, lng: -101.8552 },  # Lubbock
      { lat: 31.7619, lng: -106.4850 },  # El Paso
      { lat: 32.7357, lng: -97.1081 },   # Arlington/Ft Worth
      { lat: 30.2220, lng: -93.2174 },   # East Texas border
      { lat: 27.8006, lng: -97.3964 },   # Corpus Christi
      { lat: 25.9018, lng: -97.4975 },   # Brownsville
      { lat: 31.3069, lng: -94.7099 },   # Tyler
      { lat: 32.3668, lng: -99.9018 },   # Abilene
      { lat: 35.2220, lng: -101.8313 },  # Amarillo
      { lat: 28.0173, lng: -97.0073 },   # Victoria
      { lat: 30.0335, lng: -103.7734 },  # Midland/Odessa
      { lat: 26.2034, lng: -98.2300 },   # McAllen
      { lat: 32.3512, lng: -94.7099 },   # Longview
      { lat: 31.5804, lng: -97.1081 },   # Waco
      { lat: 33.2148, lng: -97.1331 }    # Denton
    ],
    "Utah" => [
      { lat: 40.7608, lng: -111.8910 },  # Salt Lake City
      { lat: 37.6772, lng: -113.0619 },  # St. George
      { lat: 40.2969, lng: -109.5498 },  # Vernal
      { lat: 39.5297, lng: -110.8544 },  # Price
      { lat: 39.3200, lng: -111.0937 },  # State center
      { lat: 41.2230, lng: -111.9738 },  # Logan
      { lat: 40.2677, lng: -111.0937 },  # Provo
      { lat: 38.5733, lng: -109.5498 }   # Moab
    ],
    "Vermont" => [
      { lat: 44.2601, lng: -72.5806 },   # Montpelier
      { lat: 44.4759, lng: -73.2121 },   # Burlington
      { lat: 43.2081, lng: -72.8092 },   # White River Junction
      { lat: 44.5588, lng: -72.5778 },   # State center
      { lat: 42.8509, lng: -72.5806 },   # Brattleboro
      { lat: 44.8619, lng: -72.5806 }    # St. Johnsbury
    ],
    "Virginia" => [
      { lat: 37.4316, lng: -78.6569 },   # State center
      { lat: 38.8048, lng: -77.0469 },   # Northern VA (Alexandria/Arlington)
      { lat: 36.8529, lng: -75.9780 },   # Virginia Beach area
      { lat: 37.5407, lng: -77.4360 },   # Richmond
      { lat: 36.6988, lng: -80.5836 },   # Southwest Virginia
      { lat: 37.2284, lng: -79.9414 },   # Lynchburg
      { lat: 38.0293, lng: -78.4767 },   # Charlottesville
      { lat: 37.2707, lng: -76.7075 },   # Newport News/Hampton Roads
      { lat: 38.2904, lng: -78.8784 },   # Staunton
      { lat: 36.7335, lng: -81.6856 },   # Bristol
      { lat: 37.5215, lng: -77.4360 }    # Petersburg
    ],
    "Washington" => [
      { lat: 47.6062, lng: -122.3321 },  # Seattle
      { lat: 47.2529, lng: -122.4443 },  # Tacoma
      { lat: 47.0379, lng: -122.9015 },  # Olympia
      { lat: 47.6587, lng: -117.4260 },  # Spokane
      { lat: 47.7511, lng: -120.7401 },  # State center
      { lat: 48.7519, lng: -122.4787 },  # Bellingham
      { lat: 46.2396, lng: -119.1391 },  # Richland/Tri-Cities
      { lat: 47.0379, lng: -122.9015 }   # Centralia
    ],
    "West Virginia" => [
      { lat: 38.3498, lng: -81.6326 },   # Charleston
      { lat: 39.6295, lng: -79.9553 },   # Morgantown
      { lat: 37.7767, lng: -81.1756 },   # Beckley
      { lat: 38.5976, lng: -80.4549 },   # State center
      { lat: 39.2640, lng: -77.7958 },   # Martinsburg
      { lat: 40.0692, lng: -80.7248 },   # Wheeling
      { lat: 38.4192, lng: -82.4452 }    # Huntington
    ],
    "Wisconsin" => [
      { lat: 43.0731, lng: -89.4012 },   # Madison
      { lat: 43.0389, lng: -87.9065 },   # Milwaukee
      { lat: 44.5133, lng: -88.0133 },   # Green Bay
      { lat: 46.5197, lng: -90.6882 },   # Superior
      { lat: 43.7844, lng: -88.7879 },   # State center
      { lat: 44.9537, lng: -89.6351 },   # Wisconsin Rapids
      { lat: 44.2619, lng: -88.4154 },   # Appleton
      { lat: 43.8014, lng: -91.2396 }    # La Crosse
    ],
    "Wyoming" => [
      { lat: 41.1400, lng: -104.8197 },  # Cheyenne
      { lat: 42.8666, lng: -106.3131 },  # Casper
      { lat: 44.2619, lng: -110.8544 },  # Jackson
      { lat: 44.7998, lng: -106.9561 },  # Sheridan
      { lat: 43.0759, lng: -107.2903 },  # State center
      { lat: 41.5868, lng: -109.2029 },  # Rock Springs
      { lat: 44.2998, lng: -105.5081 },  # Gillette
      { lat: 42.0661, lng: -104.8197 }   # Laramie
    ]
  }
end 