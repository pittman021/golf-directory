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
  MODEL = "gpt-4-turbo"

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
      - Course tags (from this list: #{TAG_CATEGORIES.values.flatten.join(', ')})
      - Number of holes (must be 9 or 18)
      - Par (must be a whole number)
      - Yardage (must be a whole number)
      - Green fee (must be a positive number)
      - Course type (must be one of: public_course, private_course, resort_course)
      - Website URL (if available)
      - Latitude (decimal format, e.g. 37.7749)
      - Longitude (decimal format, e.g. -122.4194)
      - Additional notes

      Format the response as a JSON object.
      Keep responses concise and factual. Focus on key information.
    PROMPT

    puts "Prompt length: #{prompt.length} characters"

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
          content = response.dig("choices", 0, "message", "content")
          puts "\nReceived response from OpenAI. Parsing JSON..."
          json_match = content.match(/\{.*\}/m)

          if json_match
            begin
              course_info = JSON.parse(json_match[0])
              course_info = clean_course_info(course_info)

              # Rewrite the description using the course info
              rewritten_description = rewrite_description(course_info)
              course_info['description'] = rewritten_description if rewritten_description.present?

              update_course(course_info)
              return course_info
            rescue JSON::ParserError => e
              puts "Error parsing matched JSON: #{e.message}"
              puts "Matched JSON: #{json_match[0]}"
              last_error = e.message
            end
          else
            puts "Could not find a valid JSON object in the response"
            puts "Response content: #{content}"
            last_error = "No JSON object found in response"
          end
        end
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
    course_info['number_of_holes'] ||= 18
    course_info['par'] ||= 72
    course_info['yardage'] ||= 6500
    course_info['green_fee'] ||= 100
    course_info['course_type'] ||= 'public_course'
    course_info['course_tags'] ||= []
    course_info['notable_holes'] ||= []
    course_info['designers'] ||= []
    course_info['tournament_history'] ||= []
    course_info['playing_tips'] ||= []
    course_info['description'] ||= ''
    course_info['history'] ||= ''
    course_info['website_url'] ||= ''
    course_info['latitude'] ||= @course.latitude
    course_info['longitude'] ||= @course.longitude
    course_info['notes'] ||= ''

    course_info['number_of_holes'] = course_info['number_of_holes'].to_i
    course_info['number_of_holes'] = 18 unless [9, 18].include?(course_info['number_of_holes'])
    course_info['par'] = course_info['par'].to_i
    course_info['par'] = 72 if course_info['par'] <= 0
    course_info['yardage'] = course_info['yardage'].to_i
    course_info['yardage'] = 6500 if course_info['yardage'] <= 0
    course_info['green_fee'] = course_info['green_fee'].to_i
    course_info['green_fee'] = 100 if course_info['green_fee'] <= 0

    valid_types = Course.course_types.keys
    course_info['course_type'] = 'public_course' unless valid_types.include?(course_info['course_type'])

    course_info['course_tags'] = [] unless course_info['course_tags'].is_a?(Array)
    valid_tags = TAG_CATEGORIES.values.flatten
    course_info['course_tags'] = course_info['course_tags'].select { |tag| valid_tags.include?(tag) }
    course_info['course_tags'] = ['traditional'] if course_info['course_tags'].empty?

    %w[notable_holes designers tournament_history playing_tips].each do |field|
      course_info[field] = [course_info[field]] unless course_info[field].is_a?(Array)
    end

    course_info
  end

  def update_course(course_info)
    notes_content = []
    notes_content << "Notable Holes: #{course_info['notable_holes'].join(', ')}" if course_info['notable_holes'].present?
    notes_content << "History: #{course_info['history']}" if course_info['history'].present?
    notes_content << "Designers: #{course_info['designers'].join(', ')}" if course_info['designers'].present?
    notes_content << "Tournament History: #{course_info['tournament_history'].join(', ')}" if course_info['tournament_history'].present?
    notes_content << "Playing Tips: #{course_info['playing_tips'].join(', ')}" if course_info['playing_tips'].present?
    notes_content << course_info['notes'] if course_info['notes'].present?
    combined_notes = notes_content.join("\n\n")

    @course.update!(
      description: course_info['description'],
      number_of_holes: course_info['number_of_holes'],
      par: course_info['par'],
      yardage: course_info['yardage'],
      green_fee: course_info['green_fee'],
      course_type: course_info['course_type'],
      course_tags: course_info['course_tags'],
      latitude: course_info['latitude'],
      longitude: course_info['longitude'],
      website_url: course_info['website_url'],
      notes: combined_notes,
      summary: {
        history: course_info['history'],
        notable_holes: course_info['notable_holes'],
        designers: course_info['designers'],
        tournament_history: course_info['tournament_history'],
        playing_tips: course_info['playing_tips']
      }
    )
  end

  def rewrite_description(course_info)
    summary = course_info.to_json
    prompt = <<~PROMPT
      Rewrite the following golf course description to sound more human, engaging, and SEO-rich — like it was written by a local golfer who knows the course inside and out.

      Course name: #{@course.name}
      Location: #{@course.locations.first&.name || 'Unknown location'}

      Existing description:
      #{course_info['description']}

      Background info (for inspiration only — do not repeat as-is):
      #{summary}

      Writing goal:
      Capture what makes this course unique, fun, and a classic New York City public golf experience.

      Constraints:
      - Include 1–2 historical facts from the background info
      - Mention at least one notable hole
      - Include one playing tip for first-time players
      - Keep the tone conversational but informative
      - Length: 150–200 words
    PROMPT

    response = @client.chat(
      parameters: {
        model: MODEL,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")&.strip
  end
end
