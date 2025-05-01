require 'csv'

namespace :export do
  desc "Export locations and courses to CSV files"
  task data: :environment do
    # Export Locations
    puts "Exporting locations..."
    CSV.open("locations.csv", "wb") do |csv|
      # Header row
      csv << [
        "id", "name", "description", "latitude", "longitude", 
        "region", "state", "country", "best_months", 
        "nearest_airports", "weather_info", "avg_green_fee",
        "lodging_price_min", "lodging_price_max", "lodging_price_currency",
        "lodging_price_last_updated", "estimated_trip_cost",
        "tags", "summary", "image_url", "reviews_count"
      ]

      # Data rows
      Location.all.each do |location|
        csv << [
          location.id,
          location.name,
          location.description,
          location.latitude,
          location.longitude,
          location.region,
          location.state,
          location.country,
          location.best_months,
          location.nearest_airports,
          location.weather_info,
          location.avg_green_fee,
          location.lodging_price_min,
          location.lodging_price_max,
          location.lodging_price_currency,
          location.lodging_price_last_updated,
          location.estimated_trip_cost,
          location.tags&.join("|"),
          location.summary,
          location.image_url,
          location.reviews_count
        ]
      end
    end
    puts "✓ Locations exported to locations.csv"

    # Export Courses
    puts "\nExporting courses..."
    CSV.open("courses.csv", "wb") do |csv|
      # Header row
      csv << [
        "id", "name", "description", "latitude", "longitude",
        "course_type", "green_fee_range", "number_of_holes",
        "par", "yardage", "website_url", "course_tags",
        "notes", "green_fee", "location_id", "image_url"
      ]

      # Data rows
      Course.includes(:location_courses).each do |course|
        location_id = course.location_courses.first&.location_id
        csv << [
          course.id,
          course.name,
          course.description,
          course.latitude,
          course.longitude,
          course.course_type,
          course.green_fee_range,
          course.number_of_holes,
          course.par,
          course.yardage,
          course.website_url,
          course.course_tags&.join("|"),
          course.notes,
          course.green_fee,
          location_id,
          course.image_url
        ]
      end
    end
    puts "✓ Courses exported to courses.csv"
    
    # Export Lodgings
    puts "\nExporting lodgings..."
    CSV.open("lodgings.csv", "wb") do |csv|
      # Header row
      csv << [
        "id", "google_place_id", "name", "types", "rating",
        "latitude", "longitude", "formatted_address", "formatted_phone_number",
        "website", "research_notes", "research_status", "research_last_attempted",
        "research_attempts", "location_id", "is_featured", "display_order",
        "photo_reference"
      ]

      # Data rows
      Lodging.includes(:location).each do |lodging|
        csv << [
          lodging.id,
          lodging.google_place_id,
          lodging.name,
          lodging.types&.join("|"),
          lodging.rating,
          lodging.latitude,
          lodging.longitude,
          lodging.formatted_address,
          lodging.formatted_phone_number,
          lodging.website,
          lodging.research_notes,
          lodging.research_status,
          lodging.research_last_attempted,
          lodging.research_attempts,
          lodging.location_id,
          lodging.is_featured,
          lodging.display_order,
          lodging.photo_reference
        ]
      end
    end
    puts "✓ Lodgings exported to lodgings.csv"

    # Export Reviews
    puts "\nExporting reviews..."
    CSV.open("reviews.csv", "wb") do |csv|
      # Header row
      csv << [
        "id", "user_id", "course_id", "rating", 
        "played_on", "course_condition", "comment",
        "created_at", "updated_at"
      ]

      # Data rows
      Review.includes(:user, :course).each do |review|
        csv << [
          review.id,
          review.user_id,
          review.course_id,
          review.rating,
          review.played_on,
          review.course_condition,
          review.comment,
          review.created_at,
          review.updated_at
        ]
      end
    end
    puts "✓ Reviews exported to reviews.csv"

    puts "\nExport complete! Files created:"
    puts "- locations.csv"
    puts "- courses.csv"
    puts "- lodgings.csv"
    puts "- reviews.csv"
  end

  desc "Export only lodgings to CSV file"
  task lodgings: :environment do
    puts "Exporting lodgings..."
    CSV.open("lodgings.csv", "wb") do |csv|
      # Header row
      csv << [
        "id", "google_place_id", "name", "types", "rating",
        "latitude", "longitude", "formatted_address", "formatted_phone_number",
        "website", "research_notes", "research_status", "research_last_attempted",
        "research_attempts", "location_id", "is_featured", "display_order",
        "photo_reference"
      ]

      # Data rows
      Lodging.includes(:location).each do |lodging|
        csv << [
          lodging.id,
          lodging.google_place_id,
          lodging.name,
          lodging.types&.join("|"),
          lodging.rating,
          lodging.latitude,
          lodging.longitude,
          lodging.formatted_address,
          lodging.formatted_phone_number,
          lodging.website,
          lodging.research_notes,
          lodging.research_status,
          lodging.research_last_attempted,
          lodging.research_attempts,
          lodging.location_id,
          lodging.is_featured,
          lodging.display_order,
          lodging.photo_reference
        ]
      end
    end
    puts "✓ Lodgings exported to lodgings.csv"
  end

  desc "Export only reviews to CSV file"
  task reviews: :environment do
    puts "Exporting reviews..."
    CSV.open("reviews.csv", "wb") do |csv|
      # Header row
      csv << [
        "id", "user_id", "course_id", "rating", 
        "played_on", "course_condition", "comment",
        "created_at", "updated_at"
      ]

      # Data rows
      Review.includes(:user, :course).each do |review|
        csv << [
          review.id,
          review.user_id,
          review.course_id,
          review.rating,
          review.played_on,
          review.course_condition,
          review.comment,
          review.created_at,
          review.updated_at
        ]
      end
    end
    puts "✓ Reviews exported to reviews.csv"
  end

  desc "Import locations and courses from CSV files"
  task import: :environment do
    puts "Starting import process..."
    
    # Diagnostic information
    puts "\nDiagnostic information for Location model:"
    puts "Available columns: #{Location.column_names.inspect}"
    
    # Import Locations
    puts "\nImporting locations..."
    CSV.foreach("locations.csv", headers: true) do |row|
      location = Location.find_or_initialize_by(id: row["id"])
      
      # Create a hash of attributes that exist on the model
      attrs = {}
      
      # Core attributes that should exist in all environments
      attrs[:name] = row["name"] if row["name"].present?
      attrs[:description] = row["description"] if row["description"].present?
      attrs[:latitude] = row["latitude"] if row["latitude"].present?
      attrs[:longitude] = row["longitude"] if row["longitude"].present?
      attrs[:region] = row["region"] if row["region"].present?
      attrs[:state] = row["state"] if row["state"].present?
      attrs[:country] = row["country"] if row["country"].present?
      
      # Optional attributes that might not exist in all environments
      if row["best_months"].present? && Location.column_names.include?("best_months")
        attrs[:best_months] = row["best_months"]
      end
      
      if row["nearest_airports"].present? && Location.column_names.include?("nearest_airports")
        attrs[:nearest_airports] = row["nearest_airports"]
      end
      
      if row["weather_info"].present? && Location.column_names.include?("weather_info")
        attrs[:weather_info] = row["weather_info"]
      end
      
      if row["avg_green_fee"].present? && Location.column_names.include?("avg_green_fee")
        attrs[:avg_green_fee] = row["avg_green_fee"]
      end
      
      if row["lodging_price_min"].present? && Location.column_names.include?("lodging_price_min")
        attrs[:lodging_price_min] = row["lodging_price_min"]
      end
      
      if row["lodging_price_max"].present? && Location.column_names.include?("lodging_price_max")
        attrs[:lodging_price_max] = row["lodging_price_max"]
      end
      
      if row["lodging_price_currency"].present? && Location.column_names.include?("lodging_price_currency")
        attrs[:lodging_price_currency] = row["lodging_price_currency"]
      end
      
      if row["lodging_price_last_updated"].present? && Location.column_names.include?("lodging_price_last_updated")
        attrs[:lodging_price_last_updated] = row["lodging_price_last_updated"]
      end
      
      if row["estimated_trip_cost"].present? && Location.column_names.include?("estimated_trip_cost")
        attrs[:estimated_trip_cost] = row["estimated_trip_cost"]
      end
      
      if row["tags"].present? && Location.column_names.include?("tags")
        attrs[:tags] = row["tags"].split("|")
      end
      
      if row["summary"].present? && Location.column_names.include?("summary")
        attrs[:summary] = row["summary"]
      end
      
      if row["image_url"].present? && Location.column_names.include?("image_url")
        attrs[:image_url] = row["image_url"]
      end
      
      if row["reviews_count"].present? && Location.column_names.include?("reviews_count")
        attrs[:reviews_count] = row["reviews_count"]
      end
      
      if location.update(attrs)
        print "."
      else
        print "F"
        puts "\nError saving location #{row['id']}: #{location.errors.full_messages.join(', ')}"
      end
    end
    puts "\n✓ Locations imported"

    # Diagnostic information
    puts "\nDiagnostic information for Course model:"
    puts "Available columns: #{Course.column_names.inspect}"
    
    # Import Courses
    puts "\nImporting courses..."
    CSV.foreach("courses.csv", headers: true) do |row|
      course = Course.find_or_initialize_by(id: row["id"])
      
      # Create a hash of attributes that exist on the model
      attrs = {}
      
      # Core attributes that should exist in all environments
      attrs[:name] = row["name"] if row["name"].present?
      attrs[:description] = row["description"] if row["description"].present?
      attrs[:latitude] = row["latitude"] if row["latitude"].present?
      attrs[:longitude] = row["longitude"] if row["longitude"].present?
      
      if row["course_type"].present? && Course.column_names.include?("course_type")
        attrs[:course_type] = row["course_type"]
      end
      
      if row["green_fee_range"].present? && Course.column_names.include?("green_fee_range")
        attrs[:green_fee_range] = row["green_fee_range"]
      end
      
      if row["number_of_holes"].present? && Course.column_names.include?("number_of_holes")
        attrs[:number_of_holes] = row["number_of_holes"]
      end
      
      if row["par"].present? && Course.column_names.include?("par")
        attrs[:par] = row["par"]
      end
      
      if row["yardage"].present? && Course.column_names.include?("yardage")
        attrs[:yardage] = row["yardage"]
      end
      
      if row["website_url"].present? && Course.column_names.include?("website_url")
        attrs[:website_url] = row["website_url"]
      end
      
      if row["course_tags"].present? && Course.column_names.include?("course_tags")
        attrs[:course_tags] = row["course_tags"].split("|")
      end
      
      if row["notes"].present? && Course.column_names.include?("notes")
        attrs[:notes] = row["notes"]
      end
      
      if row["green_fee"].present? && Course.column_names.include?("green_fee")
        attrs[:green_fee] = row["green_fee"]
      end
      
      if row["image_url"].present? && Course.column_names.include?("image_url")
        attrs[:image_url] = row["image_url"]
      end
      
      if course.update(attrs)
        # Create or update location association
        if row["location_id"].present?
          LocationCourse.find_or_create_by(
            location_id: row["location_id"],
            course_id: course.id
          )
        end
        print "."
      else
        print "F"
        puts "\nError saving course #{row['id']}: #{course.errors.full_messages.join(', ')}"
      end
    end
    puts "\n✓ Courses imported"

    # Diagnostic information
    puts "\nDiagnostic information for Lodging model:"
    puts "Available columns: #{Lodging.column_names.inspect}"
    
    # Import Lodgings
    puts "\nImporting lodgings..."
    CSV.foreach("lodgings.csv", headers: true) do |row|
      lodging = Lodging.find_or_initialize_by(id: row["id"])
      
      # Create a hash of attributes that exist on the model
      attrs = {}
      
      # Core attributes that should exist in all environments
      attrs[:google_place_id] = row["google_place_id"] if row["google_place_id"].present?
      attrs[:name] = row["name"] if row["name"].present?
      attrs[:location_id] = row["location_id"] if row["location_id"].present?
      
      # Optional attributes that might not exist in all environments
      if row["types"].present? && Lodging.column_names.include?("types")
        attrs[:types] = row["types"].split("|")
      end
      
      if row["rating"].present? && Lodging.column_names.include?("rating")
        attrs[:rating] = row["rating"]
      end
      
      if row["latitude"].present? && Lodging.column_names.include?("latitude")
        attrs[:latitude] = row["latitude"]
      end
      
      if row["longitude"].present? && Lodging.column_names.include?("longitude")
        attrs[:longitude] = row["longitude"]
      end
      
      if row["formatted_address"].present? && Lodging.column_names.include?("formatted_address")
        attrs[:formatted_address] = row["formatted_address"]
      end
      
      if row["formatted_phone_number"].present? && Lodging.column_names.include?("formatted_phone_number")
        attrs[:formatted_phone_number] = row["formatted_phone_number"]
      end
      
      if row["website"].present? && Lodging.column_names.include?("website")
        attrs[:website] = row["website"]
      end
      
      if row["research_notes"].present? && Lodging.column_names.include?("research_notes")
        attrs[:research_notes] = row["research_notes"]
      end
      
      if row["research_status"].present? && Lodging.column_names.include?("research_status")
        attrs[:research_status] = row["research_status"]
      end
      
      if row["research_last_attempted"].present? && Lodging.column_names.include?("research_last_attempted")
        attrs[:research_last_attempted] = row["research_last_attempted"]
      end
      
      if row["research_attempts"].present? && Lodging.column_names.include?("research_attempts")
        attrs[:research_attempts] = row["research_attempts"]
      end
      
      if row["is_featured"].present? && Lodging.column_names.include?("is_featured")
        attrs[:is_featured] = row["is_featured"] == "true"
      end
      
      if row["display_order"].present? && Lodging.column_names.include?("display_order")
        attrs[:display_order] = row["display_order"]
      end
      
      if row["photo_reference"].present? && Lodging.column_names.include?("photo_reference")
        attrs[:photo_reference] = row["photo_reference"]
      end
      
      if lodging.update(attrs)
        print "."
      else
        print "F"
        puts "\nError saving lodging #{row['id']}: #{lodging.errors.full_messages.join(', ')}"
      end
    end
    puts "\n✓ Lodgings imported"

    # Diagnostic information for Review model
    puts "\nDiagnostic information for Review model:"
    puts "Available columns: #{Review.column_names.inspect}"
    
    # Import Reviews
    puts "\nImporting reviews..."
    if File.exist?("reviews.csv")
      CSV.foreach("reviews.csv", headers: true) do |row|
        review = Review.find_or_initialize_by(id: row["id"])
        
        # Create a hash of attributes that exist on the model
        attrs = {}
        
        # Core attributes that should exist in all environments
        attrs[:user_id] = row["user_id"] if row["user_id"].present?
        attrs[:course_id] = row["course_id"] if row["course_id"].present?
        attrs[:rating] = row["rating"] if row["rating"].present?
        attrs[:played_on] = row["played_on"] if row["played_on"].present?
        attrs[:course_condition] = row["course_condition"] if row["course_condition"].present?
        attrs[:comment] = row["comment"] if row["comment"].present?
        
        if review.update(attrs)
          print "."
        else
          print "F"
          puts "\nError saving review #{row['id']}: #{review.errors.full_messages.join(', ')}"
        end
      end
      puts "\n✓ Reviews imported"
    else
      puts "\nSkipping reviews import - reviews.csv not found"
    end

    puts "\nImport complete!"
  end
end 