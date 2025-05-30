# app/controllers/states_controller.rb
class StatesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_state, only: [:show]

  def show
    @courses = @state.courses.ordered_by_price.includes(:reviews).limit(50)
    @total_courses_count = @state.courses.count
    @locations = @state.locations.includes(:courses, :reviews)
    @top_100_courses_count = @state.courses.where("'top_100_courses' = ANY(course_tags)").count

    
    # Get nearby locations if coordinates are available
    if @locations.any? { |l| l.latitude && l.longitude }
      @nearby_locations = Location.where.not(id: @locations.map(&:id))
                                 .near([@locations.first.latitude, @locations.first.longitude], 200)
                                 .limit(3)
    else
      @nearby_locations = Location.where.not(id: @locations.map(&:id)).limit(3)
    end

    # Set SEO meta tags
    @page_title = @state.meta_title || "Golf in #{@state.name} – Courses, Destinations & Trip Planning"
    @page_description = @state.meta_description || "Discover the best golf courses and destinations in #{@state.name}. Find top-rated courses, golf resorts, and plan your perfect golf trip."
  end

  private
    def set_state
      @state = State.friendly.find(params[:slug])
    end
end 