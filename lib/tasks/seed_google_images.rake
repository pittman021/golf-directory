require 'net/http'
require 'json'
require 'open-uri'
require 'cloudinary'

namespace :seed do

  desc "Backfill image_url for courses using Google Place API + Cloudinary"
  task course_images: :environment do
    limit = ENV['LIMIT']&.to_i
    puts "🔍 Looking for courses missing image_url..."

    courses = Course.where(image_url: nil).where.not(google_place_id: nil)

    puts "Found #{courses.count} courses without images"

    courses.find_each.with_index(1) do |course, index|
      puts "\n[#{index}/#{courses.count}] Processing: #{course.name}"

      if CourseEnrichmentService.fetch_and_update_course_image(course)
        puts "✅ Success"
      else
        puts "❌ Failed or skipped"
      end

      sleep 2 # Respect Google API rate limits
    end

    puts "\n🎉 Done processing course images."
  end

  desc "Fetch and store google_place_id for courses"
  task course_place_ids: :environment do
    courses = Course.where(google_place_id: nil)

    puts "Found #{courses.count} courses missing place_id"

    courses.find_each.with_index(1) do |course, i|
      puts "\n[#{i}/#{courses.count}] #{course.name}"
      CourseEnrichmentService.fetch_and_store_place_id(course)
      sleep 1
    end

    puts "\n🎉 Place ID enrichment complete."
  end

end
