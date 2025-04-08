# app/services/course_import_service.rb
require 'csv'

class CourseImportService
  def self.import(file)
    results = { created: 0, updated: 0, failed: 0, errors: [] }
    
    CSV.foreach(file.path, headers: true, header_converters: :symbol) do |row|
      begin
        # Find or initialize course
        course = Course.find_or_initialize_by(name: row[:name])
        
        # Find location
        location = Location.find_by(name: row[:location_name])
        unless location
          results[:errors] << "Location '#{row[:location_name]}' not found for course '#{row[:name]}'"
          results[:failed] += 1
          next
        end

        # Convert layout_tags from string to array
        layout_tags = row[:layout_tags].to_s.split(',').map(&:strip)

        # Update course attributes with all available fields
        course.assign_attributes(
          name: row[:name],
          description: row[:description],
          latitude: row[:latitude],
          longitude: row[:longitude],
          course_type: row[:course_type],
          number_of_holes: row[:number_of_holes],
          par: row[:par],
          yardage: row[:yardage],
          green_fee: row[:green_fee],
          layout_tags: layout_tags,
          website_url: row[:website_url],
          notes: row[:notes]
        )

        # Save course and create location association
        if course.new_record?
          if course.save
            LocationCourse.create!(location: location, course: course)
            results[:created] += 1
          else
            results[:errors] << "Failed to create course '#{row[:name]}': #{course.errors.full_messages.join(', ')}"
            results[:failed] += 1
          end
        else
          if course.save
            # Update location association if needed
            unless course.locations.include?(location)
              LocationCourse.create!(location: location, course: course)
            end
            results[:updated] += 1
          else
            results[:errors] << "Failed to update course '#{row[:name]}': #{course.errors.full_messages.join(', ')}"
            results[:failed] += 1
          end
        end
      rescue => e
        results[:errors] << "Error processing row for '#{row[:name]}': #{e.message}"
        results[:failed] += 1
      end
    end
    
    results
  end
end