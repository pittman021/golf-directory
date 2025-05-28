namespace :courses do
  desc "Analyze courses with sparse information that need enrichment"
  task analyze_sparse: :environment do
    puts "🔍 Analyzing courses with sparse information..."
    
    # Initialize tracking arrays
    sparse_courses = []
    well_documented_courses = []
    
    # Define thresholds for sparse content
    MIN_DESCRIPTION_WORDS = 10
    MIN_NOTES_WORDS = 5
    MIN_SUMMARY_CONTENT = 3 # For JSON summary fields
    
    # Fetch all courses
    total_courses = Course.count
    puts "Total courses in database: #{total_courses}"
    
    Course.find_each.with_index do |course, index|
      print "\rProcessing course #{index + 1}/#{total_courses}: #{course.name[0..30]}..." if (index + 1) % 50 == 0
      
      # Count words in description
      description_words = course.description.present? ? course.description.split.size : 0
      
      # Count words in notes
      notes_words = course.notes.present? ? course.notes.split.size : 0
      
      # Analyze summary content
      summary_content_score = 0
      if course.summary.present?
        if course.summary.is_a?(Hash)
          # Count non-empty values in summary hash
          summary_content_score = course.summary.values.count { |v| v.present? && v.to_s.strip.length > 10 }
        elsif course.summary.is_a?(String)
          # Try to parse as JSON, otherwise count as text
          begin
            parsed_summary = JSON.parse(course.summary)
            summary_content_score = parsed_summary.values.count { |v| v.present? && v.to_s.strip.length > 10 }
          rescue JSON::ParserError
            summary_content_score = course.summary.split.size > 10 ? 1 : 0
          end
        end
      end
      
      # Calculate sparseness score
      sparseness_indicators = []
      sparseness_indicators << "description (#{description_words} words)" if description_words < MIN_DESCRIPTION_WORDS
      sparseness_indicators << "notes (#{notes_words} words)" if notes_words < MIN_NOTES_WORDS
      sparseness_indicators << "summary (#{summary_content_score} sections)" if summary_content_score < MIN_SUMMARY_CONTENT
      sparseness_indicators << "no image" if course.image_url.blank?
      sparseness_indicators << "no website" if course.website_url.blank?
      sparseness_indicators << "default green fee" if course.green_fee == 100 # Default value from import
      sparseness_indicators << "default yardage" if course.yardage == 6500 # Default value from import
      sparseness_indicators << "default par" if course.par == 72 # Default value from import
      sparseness_indicators << "minimal tags" if course.course_tags.size <= 2
      
      # Determine if course needs enrichment
      if sparseness_indicators.size >= 3 # If 3 or more indicators of sparse data
        sparse_courses << {
          id: course.id,
          name: course.name,
          description_words: description_words,
          notes_words: notes_words,
          summary_content_score: summary_content_score,
          sparseness_indicators: sparseness_indicators,
          google_place_id: course.google_place_id,
          created_at: course.created_at,
          state: course.state || course.state&.name
        }
      else
        well_documented_courses << {
          id: course.id,
          name: course.name,
          description_words: description_words,
          notes_words: notes_words,
          summary_content_score: summary_content_score
        }
      end
    end
    
    puts "\n\n📊 Analysis Results:"
    puts "=" * 50
    puts "Total courses analyzed: #{total_courses}"
    puts "Courses needing enrichment: #{sparse_courses.size} (#{(sparse_courses.size.to_f / total_courses * 100).round(1)}%)"
    puts "Well-documented courses: #{well_documented_courses.size} (#{(well_documented_courses.size.to_f / total_courses * 100).round(1)}%)"
    
    # Group sparse courses by creation date to see patterns
    puts "\n📅 Sparse Courses by Creation Date:"
    sparse_by_date = sparse_courses.group_by { |c| c[:created_at].to_date }
    sparse_by_date.keys.sort.last(10).each do |date|
      puts "#{date}: #{sparse_by_date[date].size} courses"
    end
    
    # Show courses with Google Place IDs (easier to enrich)
    courses_with_place_ids = sparse_courses.select { |c| c[:google_place_id].present? }
    courses_without_place_ids = sparse_courses.select { |c| c[:google_place_id].blank? }
    
    puts "\n🆔 Sparse Courses Breakdown:"
    puts "With Google Place ID (easier to enrich): #{courses_with_place_ids.size}"
    puts "Without Google Place ID (harder to enrich): #{courses_without_place_ids.size}"
    
    # Show top 20 sparsest courses
    puts "\n🔍 Top 20 Sparsest Courses (most indicators):"
    puts "-" * 80
    sparse_courses.sort_by { |c| -c[:sparseness_indicators].size }.first(20).each do |course|
      puts "#{course[:name]} (ID: #{course[:id]})"
      puts "  State: #{course[:state] || 'Unknown'}"
      puts "  Issues: #{course[:sparseness_indicators].join(', ')}"
      puts "  Content: #{course[:description_words]} desc words, #{course[:notes_words]} note words, #{course[:summary_content_score]} summary sections"
      puts "  Google Place ID: #{course[:google_place_id].present? ? 'Yes' : 'No'}"
      puts
    end
    
    # Show some well-documented examples
    puts "\n✅ Examples of Well-Documented Courses:"
    puts "-" * 50
    well_documented_courses.sort_by { |c| -(c[:description_words] + c[:notes_words] + c[:summary_content_score]) }.first(5).each do |course|
      puts "#{course[:name]} (ID: #{course[:id]})"
      puts "  Content: #{course[:description_words]} desc words, #{course[:notes_words]} note words, #{course[:summary_content_score]} summary sections"
      puts
    end
    
    # Save results to files for further analysis
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    
    # Save sparse courses list
    sparse_file = Rails.root.join('tmp', "sparse_courses_#{timestamp}.csv")
    require 'csv'
    CSV.open(sparse_file, 'w') do |csv|
      csv << ['ID', 'Name', 'State', 'Description Words', 'Notes Words', 'Summary Score', 'Google Place ID', 'Issues', 'Created At']
      sparse_courses.each do |course|
        csv << [
          course[:id],
          course[:name],
          course[:state],
          course[:description_words],
          course[:notes_words],
          course[:summary_content_score],
          course[:google_place_id].present? ? 'Yes' : 'No',
          course[:sparseness_indicators].join('; '),
          course[:created_at]
        ]
      end
    end
    
    puts "\n📝 Results saved to:"
    puts "Sparse courses: #{sparse_file}"
    
    # Show enrichment recommendations
    puts "\n💡 Enrichment Recommendations:"
    puts "1. Start with courses that have Google Place IDs (#{courses_with_place_ids.size} courses)"
    puts "2. Focus on recently created courses (likely from automated imports)"
    puts "3. Prioritize courses with 'top_100' tag for better user experience"
    puts "4. Use existing enrichment services to fill missing data"
    
    # Show command to enrich courses with Google Place IDs
    if courses_with_place_ids.any?
      puts "\n🚀 To enrich courses with Google Place IDs, run:"
      puts "rails courses:enrich_sparse"
    end
  end
  
  desc "Enrich courses with sparse information using existing services"
  task enrich_sparse: :environment do
    puts "🔧 Starting enrichment of sparse courses..."
    
    # Find courses that need enrichment and have Google Place IDs
    sparse_courses = Course.where.not(google_place_id: nil)
                          .where("(description IS NULL OR LENGTH(description) < 50) OR 
                                  (notes IS NULL OR LENGTH(notes) < 25) OR 
                                  (image_url IS NULL OR image_url = '') OR
                                  (website_url IS NULL OR website_url = '')")
                          .limit(20) # Process in smaller batches to start
    
    puts "Found #{sparse_courses.count} courses to enrich"
    
    enriched_count = 0
    failed_count = 0
    
    sparse_courses.find_each.with_index do |course, index|
      puts "\n#{index + 1}/#{sparse_courses.count}: Enriching #{course.name}..."
      puts "  Current state:"
      puts "    Description: #{course.description.present? ? "#{course.description.length} chars" : 'None'}"
      puts "    Notes: #{course.notes.present? ? "#{course.notes.length} chars" : 'None'}"
      puts "    Image: #{course.image_url.present? ? 'Yes' : 'No'}"
      puts "    Website: #{course.website_url.present? ? 'Yes' : 'No'}"
      
      begin
        # Use the existing GetCourseInfoService to enrich the course
        service = GetCourseInfoService.new(course)
        result = service.gather_info
        
        if result.present?
          # Reload the course to see the updates
          course.reload
          
          enriched_count += 1
          puts "✅ Successfully enriched #{course.name}"
          puts "  Updated state:"
          puts "    Description: #{course.description.present? ? "#{course.description.length} chars" : 'None'}"
          puts "    Notes: #{course.notes.present? ? "#{course.notes.length} chars" : 'None'}"
          puts "    Image: #{course.image_url.present? ? 'Yes' : 'No'}"
          puts "    Website: #{course.website_url.present? ? 'Yes' : 'No'}"
          puts "    Course type: #{course.course_type}"
          puts "    Tags: #{course.course_tags.join(', ')}"
        else
          failed_count += 1
          puts "⚠️ No enrichment data returned for #{course.name}"
        end
        
        # Add delay to respect API rate limits (OpenAI)
        sleep(3)
        
      rescue StandardError => e
        failed_count += 1
        puts "❌ Error enriching #{course.name}: #{e.message}"
        puts "   #{e.backtrace.first}" if e.backtrace.present?
      end
    end
    
    puts "\n📊 Enrichment Summary:"
    puts "Successfully enriched: #{enriched_count} courses"
    puts "Failed to enrich: #{failed_count} courses"
    puts "Total processed: #{enriched_count + failed_count} courses"
    
    if enriched_count > 0
      puts "\n💡 To continue enriching more courses, run the task again."
      puts "The task processes #{sparse_courses.limit_value} courses at a time to manage API costs."
    end
  end
end 