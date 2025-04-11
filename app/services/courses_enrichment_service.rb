# This service handles enrichment of individual golf courses.
# It focuses on course-specific data including:
# - Course insights and descriptions
# - Local tips and recommendations
# - Hole-by-hole details
# - Course-specific metadata
#
# Usage:
#   service = CoursesEnrichmentService.new(course)
#   service.enrich
#
# This service is used by:
# - GolfDestinationEnrichmentService for course-specific data
# - Rake tasks for course updates
# - Manual course enrichment processes
#
# Note: This service works at the individual course level,
# unlike GolfDestinationEnrichmentService which handles
# entire destinations.

class CoursesEnrichmentService
  def initialize(course)
    @course = course
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])
  end

  def enrich
    begin
      puts "Enriching course: #{@course.name}..."
      
      # Generate course insights
      course_insights = generate_course_insights
      @course.update!(course_insights: course_insights) if course_insights.present?

      # Generate local tips
      local_tips = generate_local_tips
      @course.update!(local_tips: local_tips) if local_tips.present?

      # Generate hole-by-hole description
      hole_descriptions = generate_hole_descriptions
      @course.update!(hole_descriptions: hole_descriptions) if hole_descriptions.present?

      true
    rescue StandardError => e
      puts "Error enriching course #{@course.name}: #{e.message}"
      false
    end
  end

  private

  def generate_course_insights
    prompt = <<~PROMPT
      Create detailed insights about #{@course.name} in #{@course.location.name}.
      Include:
      - Course design and layout
      - Signature holes
      - Course conditions
      - Difficulty level
      - Best strategies for playing
      - Notable features or challenges
      - Historical significance if any
      
      Format the response in clear sections with specific details.
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4-turbo-preview",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  def generate_local_tips
    prompt = <<~PROMPT
      Create local tips for playing #{@course.name} in #{@course.location.name}.
      Include:
      - Best times to play
      - Local knowledge about the course
      - Tips for specific holes
      - Practice facilities
      - Pro shop recommendations
      - Food and beverage options
      - Caddie or cart recommendations
      
      Format as practical tips with specific details.
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4-turbo-preview",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end

  def generate_hole_descriptions
    prompt = <<~PROMPT
      Create detailed descriptions for each hole at #{@course.name}.
      For each hole include:
      - Yardage
      - Par
      - Key features
      - Strategic considerations
      - Common mistakes to avoid
      - Best approach for different skill levels
      
      Format as a numbered list with clear sections for each hole.
    PROMPT

    response = @client.chat(
      parameters: {
        model: "gpt-4-turbo-preview",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7
      }
    )

    response.dig("choices", 0, "message", "content")
  end
end 