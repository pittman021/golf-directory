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
        "avg_lodging_cost_per_night", "estimated_trip_cost",
        "tags", "summary", "image_url", "reviews_count",
        "lodging_price_min", "lodging_price_max", "lodging_price_currency", 
        "lodging_price_last_updated"
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
          location.avg_lodging_cost_per_night,
          location.estimated_trip_cost,
          location.tags&.join("|"),
          location.summary,
          location.image_url,
          location.reviews_count,
          location.lodging_price_min,
          location.lodging_price_max,
          location.lodging_price_currency,
          location.lodging_price_last_updated
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
        "par", "yardage", "website_url", "layout_tags",
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
          course.layout_tags&.join("|"),
          course.notes,
          course.green_fee,
          location_id,
          course.image_url
        ]
      end
    end
    puts "✓ Courses exported to courses.csv"

    puts "\nExport complete! Files created:"
    puts "- locations.csv"
    puts "- courses.csv"
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
      
      if row["avg_lodging_cost_per_night"].present? && Location.column_names.include?("avg_lodging_cost_per_night")
        attrs[:avg_lodging_cost_per_night] = row["avg_lodging_cost_per_night"]
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
      
      if row["layout_tags"].present? && Course.column_names.include?("layout_tags")
        attrs[:layout_tags] = row["layout_tags"].split("|")
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

    puts "\nImport complete!"
  end
end 