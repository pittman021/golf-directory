require 'openai'

class GolfDestinationEnrichmentService
  def initialize(location)
    @location = location
    @courses = location.courses
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai[:api_key])
  end

  def enrich
    begin
      puts "Generating summary for #{@location.name}..."
      
      # Generate comprehensive summary combining all aspects
      summary = generate_comprehensive_summary
      
      if summary.nil? || summary.empty?
        puts "Failed to generate summary - empty response from OpenAI"
        return false
      end
      
      # Update the location's summary
      @location.update!(summary: summary)
      
      true
    rescue StandardError => e
      puts "Error: #{e.message}"
      puts "Error type: #{e.class}"
      if e.respond_to?(:response)
        puts "Response body: #{e.response.body}"
      end
      false
    end
  end

  def enrich_location(location)
    return if location.trip_summary.present? && location.travel_tips.present?

    puts "Enriching location: #{location.name}"
    
    # Generate trip summary
    trip_summary = generate_trip_summary(location)
    location.update!(trip_summary: trip_summary) if trip_summary.present?

    # Generate travel tips
    # travel_tips = generate_travel_tips(location)
    # location.update!(travel_tips: travel_tips) if travel_tips.present?

    # # Generate SEO content
    # seo_content = generate_seo_content(location)
    # location.update!(seo_content: seo_content) if seo_content.present?

    # Process each course in the location
    location.courses.each do |course|
      enrich_course(course)
    end
  end

  def enrich_course(course)
    return if course.course_insights.present? && course.local_tips.present?

    puts "Enriching course: #{course.name}"
    
    # Generate course insights
    course_insights = generate_course_insights(course)
    course.update!(course_insights: course_insights) if course_insights.present?

    # Generate local tips
    local_tips = generate_local_tips(course)
    course.update!(local_tips: local_tips) if local_tips.present?

    # Generate hole-by-hole description
    hole_descriptions = generate_hole_descriptions(course)
    course.update!(hole_descriptions: hole_descriptions) if hole_descriptions.present?
  end

  private

  def generate_comprehensive_summary
    sections = {
      'destination_overview' => generate_section('destination_overview'),
      'golf_experience' => generate_section('golf_experience'),
      'travel_information' => generate_section('travel_information'),
      'local_attractions' => generate_section('local_attractions'),
      'practical_tips' => generate_section('practical_tips')
    }
  end

  def generate_section(section_name)
    prompt = case section_name
    when 'destination_overview'
      "Create a brief introduction to #{@location.name}, #{@location.state}. Include why it's a great golf destination and its unique characteristics."
    when 'golf_experience'
      "Describe the golf experience at #{@location.name}. Include notable courses, course highlights, best times to play, and typical course conditions."
    when 'travel_information'
      "Provide travel information for #{@location.name}. Include best times to visit, weather patterns, transportation options, and airport information."
    when 'local_attractions'
      "List local attractions near #{@location.name}. Include points of interest, dining recommendations, accommodation options, and other activities."
    when 'practical_tips'
      "Provide practical tips for visiting #{@location.name}. Include packing recommendations, budget considerations, local customs, and safety tips."
    end

    puts "Generating #{section_name} for #{@location.name}..."
    
    begin
      response = @client.chat(
        parameters: {
          model: "gpt-4-turbo-preview",
          messages: [{ role: "user", content: prompt }],
          temperature: 0.7
        }
      )
      
      content = response.dig("choices", 0, "message", "content")
      
      if content.nil? || content.empty?
        puts "Warning: Empty content in OpenAI response for #{section_name}"
        return nil
      end
      
      content
    rescue StandardError => e
      puts "API Error Details for #{section_name}:"
      puts "Error message: #{e.message}"
      puts "Error type: #{e.class}"
      if e.respond_to?(:response)
        puts "Response body: #{e.response.body}"
      end
      nil
    end
  end

  def generate_trip_summary(location)
    prompt = <<~PROMPT
      Create a detailed trip summary for a golf destination in #{location.name}, #{location.state}. 
      Include:
      - Best times to visit
      - Typical weather conditions
      - Notable golf courses in the area
      - Local attractions and activities
      - Dining recommendations
      - Accommodation options
      - Transportation tips
      
      Format the response in clear sections with bullet points where appropriate.
      Keep the tone professional and informative.
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

  def generate_travel_tips(location)
    prompt = <<~PROMPT
      Create practical travel tips for visiting #{location.name}, #{location.state} for a golf trip.
      Include:
      - Best ways to get there
      - Local transportation options
      - Packing recommendations
      - Budget considerations
      - Local customs or etiquette
      - Safety tips
      - Best ways to book tee times
      
      Format as a list of practical tips with brief explanations.
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

  def generate_seo_content(location)
    prompt = <<~PROMPT
      Create SEO-optimized content for #{location.name}, #{location.state} as a golf destination.
      Include:
      - A compelling introduction
      - Key features and attractions
      - Why it's a great golf destination
      - Unique selling points
      - Call to action
      
      Use natural language and include relevant keywords without keyword stuffing.
      Keep the content engaging and informative.
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

  def generate_course_insights(course)
    prompt = <<~PROMPT
      Create detailed insights about #{course.name} in #{course.location.name}.
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

  def generate_local_tips(course)
    prompt = <<~PROMPT
      Create local tips for playing #{course.name} in #{course.location.name}.
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

  def generate_hole_descriptions(course)
    prompt = <<~PROMPT
      Create detailed descriptions for each hole at #{course.name} in #{course.location.name}.
      For each hole, include:
      - Yardage
      - Par
      - Key features
      - Hazards
      - Best approach
      - Tips for playing
      
      Format as a numbered list with detailed descriptions for each hole.
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

  def generate_trip_summary
    {
      best_time_to_visit: generate_best_time_to_visit,
      weather_overview: generate_weather_overview,
      notable_courses: generate_notable_courses,
      local_attractions: generate_local_attractions,
      dining_recommendations: generate_dining_recommendations,
      accommodation_options: generate_accommodation_options,
      transportation_tips: generate_transportation_tips
    }
  end

  def generate_travel_tips
    {
      transportation: generate_transportation_info,
      packing_list: generate_packing_list,
      local_customs: generate_local_customs,
      safety_tips: generate_safety_tips,
      budgeting_advice: generate_budgeting_advice
    }
  end

  def generate_seo_content
    {
      meta_description: generate_meta_description,
      introduction: generate_introduction,
      key_features: generate_key_features,
      call_to_action: generate_call_to_action
    }
  end

  def generate_best_time_to_visit
    # Analyze weather data and course conditions
    # Return a string with the best months to visit
    "The best time to visit #{@location.name} is typically between [months] when the weather is [condition] and the courses are in [condition]."
  end

  def generate_weather_overview
    # Analyze historical weather data
    # Return a string describing typical weather patterns
    "In #{@location.name}, you can expect [weather patterns] throughout the year. Summers are [description] while winters are [description]."
  end

  def generate_notable_courses
    # Select and describe the most notable courses
    @courses.limit(3).map do |course|
      {
        name: course.name,
        description: course.description,
        highlights: course.highlights
      }
    end
  end

  def generate_local_attractions
    # Generate a list of local attractions
    [
      "Explore the [attraction]",
      "Visit [landmark]",
      "Experience [local activity]"
    ]
  end

  def generate_dining_recommendations
    # Generate dining recommendations
    [
      {
        name: "[Restaurant Name]",
        cuisine: "[Cuisine Type]",
        description: "[Description]"
      }
    ]
  end

  def generate_accommodation_options
    # Generate accommodation options
    [
      {
        type: "[Accommodation Type]",
        description: "[Description]",
        price_range: "[Price Range]"
      }
    ]
  end

  def generate_transportation_tips
    # Generate transportation tips
    "Getting around #{@location.name} is [description]. The best way to travel between courses is [method]."
  end

  def generate_transportation_info
    # Generate detailed transportation information
    {
      airport: "[Nearest Airport]",
      car_rental: "[Car Rental Info]",
      public_transport: "[Public Transport Info]"
    }
  end

  def generate_packing_list
    # Generate a packing list based on weather and activities
    [
      "Golf clubs and equipment",
      "Weather-appropriate clothing",
      "Sunscreen and protective gear"
    ]
  end

  def generate_local_customs
    # Generate information about local customs
    "When visiting #{@location.name}, it's important to [customs info]."
  end

  def generate_safety_tips
    # Generate safety tips
    [
      "Keep valuables secure",
      "Be aware of local wildlife",
      "Follow course safety guidelines"
    ]
  end

  def generate_budgeting_advice
    # Generate budgeting advice
    "A typical golf trip to #{@location.name} costs between [price range]. Major expenses include [expenses]."
  end

  def generate_meta_description
    # Generate SEO meta description
    "Discover the best golf courses in #{@location.name}. Plan your perfect golf vacation with our comprehensive guide to courses, weather, and local attractions."
  end

  def generate_introduction
    # Generate an engaging introduction
    "#{@location.name} is a premier golf destination offering [number] world-class courses set against [scenery]. Whether you're a seasoned pro or a casual player, you'll find the perfect course for your game."
  end

  def generate_key_features
    # Generate key features
    [
      "#{@courses.count} championship golf courses",
      "Year-round golfing weather",
      "Luxury accommodations",
      "World-class dining"
    ]
  end

  def generate_call_to_action
    # Generate a compelling call to action
    "Ready to experience the best golf #{@location.name} has to offer? Book your tee times today and start planning your dream golf vacation!"
  end
end 