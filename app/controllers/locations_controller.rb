# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  def index
    @locations = Location.includes(:courses, :reviews).all
    
    # Filter by country if parameter present
    @locations = @locations.where(country: params[:country]) if params[:country].present?
    
    # Filter by price range if parameter present
    if params[:price_range].present?
      @locations = @locations.joins(:courses)
                           .where(courses: { green_fee_range: params[:price_range] })
                           .distinct
    end
  end

  def show
    @location = Location.includes(:courses).find(params[:id])
    @courses = @location.courses.includes(:reviews)
    
    # Add explicit debugging
    Rails.logger.debug "=== Location Debug ==="
    Rails.logger.debug "Location: #{@location.name}"
    Rails.logger.debug "Coordinates: #{@location.latitude}, #{@location.longitude}"
    Rails.logger.debug "Courses count: #{@courses.count}"
    Rails.logger.debug "Course coordinates:"
    @courses.each do |course|
      Rails.logger.debug "  #{course.name}: #{course.latitude}, #{course.longitude}"
    end
    Rails.logger.debug "===================="

    # Get nearby locations if coordinates are available
    if @location.latitude && @location.longitude
      @nearby_locations = Location.where.not(id: @location.id)
                                 .near([@location.latitude, @location.longitude], 50)
                                 .limit(5)
    else
      @nearby_locations = Location.where.not(id: @location.id).limit(5)
    end

    # Add these debug lines temporarily
    puts "DEBUG: Map ID from credentials: #{Rails.application.credentials.google_maps_map_id}"
    puts "DEBUG: API Key from credentials: #{Rails.application.credentials.google_maps_map_id.present?}"
  end
end
