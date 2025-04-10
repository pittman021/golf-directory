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
        "tags", "summary"
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
          location.summary
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
        "notes", "green_fee", "location_id"
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
          location_id
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

    # Import Locations
    puts "\nImporting locations..."
    CSV.foreach("locations.csv", headers: true) do |row|
      location = Location.find_or_initialize_by(id: row["id"])
      location.assign_attributes(
        name: row["name"],
        description: row["description"],
        latitude: row["latitude"],
        longitude: row["longitude"],
        region: row["region"],
        state: row["state"],
        country: row["country"],
        best_months: row["best_months"],
        nearest_airports: row["nearest_airports"],
        weather_info: row["weather_info"],
        avg_green_fee: row["avg_green_fee"],
        avg_lodging_cost_per_night: row["avg_lodging_cost_per_night"],
        estimated_trip_cost: row["estimated_trip_cost"],
        tags: row["tags"]&.split("|"),
        summary: row["summary"]
      )
      if location.save
        print "."
      else
        print "F"
      end
    end
    puts "\n✓ Locations imported"

    # Import Courses
    puts "\nImporting courses..."
    CSV.foreach("courses.csv", headers: true) do |row|
      course = Course.find_or_initialize_by(id: row["id"])
      course.assign_attributes(
        name: row["name"],
        description: row["description"],
        latitude: row["latitude"],
        longitude: row["longitude"],
        course_type: row["course_type"],
        green_fee_range: row["green_fee_range"],
        number_of_holes: row["number_of_holes"],
        par: row["par"],
        yardage: row["yardage"],
        website_url: row["website_url"],
        layout_tags: row["layout_tags"]&.split("|"),
        notes: row["notes"],
        green_fee: row["green_fee"]
      )
      if course.save
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
      end
    end
    puts "\n✓ Courses imported"

    puts "\nImport complete!"
  end
end 