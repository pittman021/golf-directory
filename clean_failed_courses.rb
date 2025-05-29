#!/usr/bin/env ruby

puts '🧹 CLEANING UP FAILED COURSES LOG'
puts '=' * 50

# Read the old messy format
old_file = 'log/failed_courses_simple.txt'
new_file = 'log/failed_courses_simple_clean.txt'

failed_courses = []
if File.exist?(old_file)
  File.readlines(old_file).each do |line|
    line = line.strip
    next if line.empty? || line.start_with?('=') || line.start_with?('Failed') || line.start_with?('Format:') || line.start_with?('-')
    
    # Extract from old format: "ID | Course Name | State | Website URL | Error Type"
    parts = line.split(' | ')
    if parts.length >= 5 && parts[0].match?(/^\d+$/)
      failed_courses << {
        id: parts[0].strip,
        name: parts[1].strip,
        state: parts[2].strip,
        url: parts[3].strip,
        error_type: parts[4].strip
      }
    end
  end
end

# Remove duplicates based on ID
unique_courses = failed_courses.uniq { |course| course[:id] }

puts "Found #{failed_courses.count} total entries"
puts "Unique courses: #{unique_courses.count}"

# Write clean format
File.open(new_file, 'w') do |f|
  f.puts "ID|Course Name|State|Website URL|Error Type|Date"
  unique_courses.each do |course|
    f.puts "#{course[:id]}|#{course[:name]}|#{course[:state]}|#{course[:url]}|#{course[:error_type]}|2025-05-28"
  end
end

puts "✅ Created clean file: #{new_file}"
puts "📋 Sample entries:"
unique_courses.first(5).each { |c| puts "  #{c[:id]}|#{c[:name]}|#{c[:state]}|#{c[:url]}|#{c[:error_type]}|2025-05-28" }

puts "\n💡 To replace the old file:"
puts "mv #{new_file} #{old_file}" 