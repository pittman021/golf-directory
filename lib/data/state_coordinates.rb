module Data
  StateCoordinates = {
    # "Alabama" => [ { lat: 32.8067, lng: -86.7911 } ],  # State center
    # "Alaska" => [ { lat: 64.2008, lng: -149.4937 } ],
    # "Arizona" => [ { lat: 34.0489, lng: -111.0937 } ],
    # "Arkansas" => [ { lat: 34.9697, lng: -92.3731 } ],
    "California" => [
      { lat: 36.7783, lng: -119.4179 },  # Central CA (Fresno)
      { lat: 34.0522, lng: -118.2437 },  # Los Angeles
      { lat: 33.8121, lng: -117.9190 },  # Anaheim
      { lat: 32.7157, lng: -117.1611 },  # San Diego
      { lat: 36.6002, lng: -121.8947 },  # Monterey
      { lat: 37.7749, lng: -122.4194 },  # San Francisco
      { lat: 38.5816, lng: -121.4944 },  # Sacramento
      { lat: 34.9592, lng: -116.4194 },  # Inland Desert
      { lat: 34.4208, lng: -119.6982 },  # Santa Barbara
      { lat: 35.3733, lng: -119.0187 }   # Bakersfield
    ],
    "Colorado" => [ { lat: 39.5501, lng: -105.7821 } ],
    "Connecticut" => [ { lat: 41.6032, lng: -73.0877 } ],
    "Delaware" => [ { lat: 38.9108, lng: -75.5277 } ],
    "Florida" => [
      { lat: 27.9944, lng: -81.7603 },   # State center
      { lat: 25.7617, lng: -80.1918 },   # Miami
      { lat: 28.5383, lng: -81.3792 },   # Orlando
      { lat: 30.3322, lng: -81.6557 },   # Jacksonville
      { lat: 26.6406, lng: -81.8723 },   # Fort Myers/Naples
      { lat: 27.9506, lng: -82.4572 }    # Tampa
    ],
    "Georgia" => [
      { lat: 32.1656, lng: -82.9001 },   # State center
      { lat: 33.7490, lng: -84.3880 },   # Atlanta
      { lat: 31.1499, lng: -81.4915 },   # Brunswick / St. Simons
      { lat: 32.0809, lng: -81.0912 }    # Savannah
    ],
    "Hawaii" => [ { lat: 20.7967, lng: -156.3319 } ],
    "Idaho" => [ { lat: 44.0682, lng: -114.742 } ],
    "Illinois" => [ { lat: 40.6331, lng: -89.3985 } ],
    "Indiana" => [ { lat: 40.2672, lng: -86.1349 } ],
    "Iowa" => [ { lat: 41.8780, lng: -93.0977 } ],
    "Kansas" => [ { lat: 39.0119, lng: -98.4842 } ],
    "Kentucky" => [ { lat: 37.8393, lng: -84.2700 } ],
    "Louisiana" => [ { lat: 30.9843, lng: -91.9623 } ],
    "Maine" => [ { lat: 45.2538, lng: -69.4455 } ],
    "Maryland" => [ { lat: 39.0458, lng: -76.6413 } ],
    "Massachusetts" => [ { lat: 42.4072, lng: -71.3824 } ],
    "Michigan" => [ { lat: 44.3148, lng: -85.6024 } ],
    "Minnesota" => [ { lat: 46.7296, lng: -94.6859 } ],
    "Mississippi" => [ { lat: 32.3547, lng: -89.3985 } ],
    "Missouri" => [ { lat: 37.9643, lng: -91.8318 } ],
    "Montana" => [ { lat: 46.8797, lng: -110.3626 } ],
    "Nebraska" => [ { lat: 41.4925, lng: -99.9018 } ],
    "Nevada" => [ { lat: 38.8026, lng: -116.4194 } ],
    "New Hampshire" => [ { lat: 43.1939, lng: -71.5724 } ],
    "New Jersey" => [ { lat: 40.0583, lng: -74.4057 } ],
    "New Mexico" => [ { lat: 34.5199, lng: -105.8701 } ],
    "New York" => [
      { lat: 43.0000, lng: -75.0000 },   # State center
      { lat: 40.7128, lng: -74.0060 },   # NYC metro
      { lat: 42.8864, lng: -78.8784 },   # Buffalo
      { lat: 43.1566, lng: -77.6088 },   # Rochester
      { lat: 42.6526, lng: -73.7562 }    # Albany
    ],
    "North Carolina" => [
      { lat: 35.7596, lng: -79.0193 },   # State center
      { lat: 35.2271, lng: -80.8431 },   # Charlotte
      { lat: 35.7796, lng: -78.6382 },   # Raleigh
      { lat: 34.2257, lng: -77.9447 },   # Wilmington
      { lat: 35.5951, lng: -82.5515 }    # Asheville
    ],
    "North Dakota" => [ { lat: 47.5515, lng: -101.002 } ],
    "Ohio" => [ { lat: 40.4173, lng: -82.9071 } ],
    "Oklahoma" => [ { lat: 35.4676, lng: -97.5164 } ],
    "Oregon" => [ { lat: 43.8041, lng: -120.5542 } ],
    "Pennsylvania" => [ { lat: 41.2033, lng: -77.1945 } ],
    "Rhode Island" => [ { lat: 41.5801, lng: -71.4774 } ],
    "South Carolina" => [ { lat: 33.8361, lng: -81.1637 } ],
    "South Dakota" => [ { lat: 43.9695, lng: -99.9018 } ],
    "Tennessee" => [ { lat: 35.5175, lng: -86.5804 } ],
    "Texas" => [
      { lat: 31.9686, lng: -99.9018 },   # Central TX
      { lat: 29.7604, lng: -95.3698 },   # Houston
      { lat: 30.2672, lng: -97.7431 },   # Austin
      { lat: 32.7767, lng: -96.7970 },   # Dallas
      { lat: 29.4241, lng: -98.4936 },   # San Antonio
      { lat: 33.5779, lng: -101.8552 },  # Lubbock
      { lat: 31.7619, lng: -106.4850 },  # El Paso
      { lat: 32.7357, lng: -97.1081 },   # Arlington/Ft Worth
      { lat: 30.2220, lng: -93.2174 }    # East Texas border
    ],
    "Utah" => [ { lat: 39.3200, lng: -111.0937 } ],
    "Vermont" => [ { lat: 44.5588, lng: -72.5778 } ],
    "Virginia" => [
      { lat: 37.4316, lng: -78.6569 },   # State center
      { lat: 38.8048, lng: -77.0469 },   # Northern VA (Alexandria/Arlington)
      { lat: 36.8529, lng: -75.9780 },   # Virginia Beach area
      { lat: 37.5407, lng: -77.4360 },   # Richmond
      { lat: 36.6988, lng: -80.5836 }    # Southwest Virginia (Hillsville/Galax)
    ],
    "Washington" => [ { lat: 47.7511, lng: -120.7401 } ],
    "West Virginia" => [ { lat: 38.5976, lng: -80.4549 } ],
    "Wisconsin" => [ { lat: 43.7844, lng: -88.7879 } ],
    "Wyoming" => [ { lat: 43.0759, lng: -107.2903 } ]
  }
end 