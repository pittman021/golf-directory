# GetCourseInfoService
#
# This service is responsible for gathering detailed information about a golf course
# using ChatGPT. It requires a course to already exist in the database and focuses on
# gathering specific information about that course.
#
# Usage:
#   service = GetCourseInfoService.new(course)
#   course_info = service.gather_info
#
# Process:
# 1. Takes an existing course from the database
# 2. Uses ChatGPT to gather information about:
#    - Course description
#    - Notable holes
#    - Course history
#    - Designers
#    - Tournament history
#    - Playing tips
#    - Layout tags
#    - Notes
#
# Note: This service requires:
# - A valid course record in the database
# - OpenAI API credentials
# - Internet connection for ChatGPT API calls
#
# Model: gpt-3.5-turbo
# - Cost effective for structured data
# - Input: $0.0010 / 1K tokens
# - Output: $0.0020 / 1K tokens

class GetCourseInfoService
  MAX_RETRIES = 3
  INITIAL_RETRY_DELAY = 1 # seconds
  MODEL = "gpt-3.5-turbo"

  def initialize(course)
    @course = course
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])
  end

  def gather_info
    return unless @course.present?

    puts "\nGathering information for course: #{@course.name}"
    puts "Course ID: #{@course.id}"
    puts "Using model: #{MODEL}"
    
    get_course_info
  end

  private

  def get_course_info
    prompt = <<~PROMPT
      Please provide detailed information about the golf course: #{@course.name}
      Include:
      - Course description
      - Notable holes
      - Course history
      - Designers
      - Tournament history
      - Playing tips
      - Layout features (from this list: #{Course::LAYOUT_TAGS.join(', ')})
      - Number of holes (must be 9 or 18)
      - Par (must be a whole number)
      - Yardage (must be a whole number)
      - Green fee (must be a positive number)
      - Course type (must be one of: public_course, private_course, resort_course)
      - Website URL (if available)
      - Additional notes
      
      Format the response as a JSON object with these keys:
      {
        "description": "string",
        "notable_holes": ["string"],
        "history": "string",
        "designers": ["string"],
        "tournament_history": ["string"],
        "playing_tips": ["string"],
        "layout_tags": ["string"],
        "number_of_holes": integer,
        "par": integer,
        "yardage": integer,
        "green_fee": integer,
        "course_type": "string",
        "website_url": "string",
        "notes": "string"
      }
      
      For layout_tags, only use tags from the provided list.
      For course_type, only use one of: public_course, private_course, resort_course
      For number_of_holes, only use 9 or 18
      For par, use a whole number (typically between 60-75)
      For yardage, use a whole number (typically between 5000-8000)
      For green_fee, use a positive number
      For notes, include any additional relevant information that doesn't fit in other categories.
      
      Keep responses concise and factual. Focus on key information.
    PROMPT

    retry_count = 0
    last_error = nil

    while retry_count < MAX_RETRIES
      begin
        puts "\nMaking request to ChatGPT (attempt #{retry_count + 1}/#{MAX_RETRIES})..."
        response = @client.chat(
          parameters: {
            model: MODEL,
            messages: [{ role: "user", content: prompt }],
            temperature: 0.7
          }
        )

        if response['error'].present?
          error_message = response['error']['message'] || response['error'].to_s
          puts "OpenAI API Error: #{error_message}"
          last_error = error_message
        else
          course_info = JSON.parse(response.dig("choices", 0, "message", "content"))
          
          # Validate and clean the data
          course_info = clean_course_info(course_info)
          
          # Update the course with the gathered information
          update_course(course_info)
          
          return course_info
        end
      rescue JSON::ParserError => e
        puts "Error parsing ChatGPT response: #{e.message}"
        last_error = e.message
      rescue Faraday::ServerError => e
        puts "OpenAI server error (attempt #{retry_count + 1}): #{e.message}"
        last_error = e.message
      rescue => e
        puts "Unexpected error getting course information: #{e.message}"
        last_error = e.message
      end

      retry_count += 1
      if retry_count < MAX_RETRIES
        delay = INITIAL_RETRY_DELAY * (2 ** (retry_count - 1))
        puts "Retrying in #{delay} seconds..."
        sleep delay
      end
    end

    puts "Failed to get course information after #{MAX_RETRIES} attempts. Last error: #{last_error}"
    nil
  end

  def clean_course_info(course_info)
    # Ensure number_of_holes is 9 or 18
    course_info['number_of_holes'] = course_info['number_of_holes'].to_i
    course_info['number_of_holes'] = 18 unless [9, 18].include?(course_info['number_of_holes'])

    # Ensure par is a whole number
    course_info['par'] = course_info['par'].to_i
    course_info['par'] = 72 if course_info['par'] <= 0

    # Ensure yardage is a whole number
    course_info['yardage'] = course_info['yardage'].to_i
    course_info['yardage'] = 6500 if course_info['yardage'] <= 0

    # Ensure green_fee is a positive number
    course_info['green_fee'] = course_info['green_fee'].to_i
    course_info['green_fee'] = 100 if course_info['green_fee'] <= 0

    # Ensure course_type is valid
    valid_types = Course.course_types.keys
    course_info['course_type'] = 'public_course' unless valid_types.include?(course_info['course_type'])

    # Ensure course_tags are valid
    valid_tags = TAG_CATEGORIES.values.flatten
    course_info['course_tags'] = course_info['course_tags'].select { |tag| valid_tags.include?(tag) }
    course_info['course_tags'] = ['traditional'] if course_info['course_tags'].empty?

    course_info
  end

  def update_course(course_info)
    @course.update!(
      description: course_info['description'],
      number_of_holes: course_info['number_of_holes'],
      par: course_info['par'],
      yardage: course_info['yardage'],
      green_fee: course_info['green_fee'],
      course_type: course_info['course_type'],
      course_tags: course_info['course_tags'],
      website_url: course_info['website_url'],
      notes: [
        "Notable Holes: #{course_info['notable_holes'].join(', ')}",
        "History: #{course_info['history']}",
        "Designers: #{course_info['designers'].join(', ')}",
        "Tournament History: #{course_info['tournament_history'].join(', ')}",
        "Playing Tips: #{course_info['playing_tips'].join(', ')}"
      ].join("\n\n")
    )
  end
end 