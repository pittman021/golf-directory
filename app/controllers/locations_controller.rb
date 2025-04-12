# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  include ActionView::Helpers::NumberHelper

  def index
    @locations = Location.includes(:courses, :reviews).all
    
    # Filter by region if parameter present
    @locations = @locations.where(region: params[:region]) if params[:region].present?
    
    # Filter by state if parameter present
    @locations = @locations.where(state: params[:state]) if params[:state].present?
    
    # Filter by price range if parameter present
    if params[:price_range].present?
      @locations = @locations.joins(:courses)
                           .where(courses: { green_fee_range: params[:price_range] })
                           .distinct
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def states_for_region
    if params[:region].present? && params[:region] != ""
      states = Location.where(region: params[:region]).distinct.pluck(:state).compact.sort
    else
      states = Location.distinct.pluck(:state).compact.sort
    end
    render json: states
  end

  def show
    @location = Location.includes(:courses).find(params[:id])
    @courses = @location.courses.ordered_by_price.includes(:reviews)
    
    # Add explicit debugging
    Rails.logger.debug "=== Location Debug ==="
    Rails.logger.debug "Location: #{@location.name}"
    Rails.logger.debug "Courses count: #{@courses.count}"
    Rails.logger.debug "Course prices:"
    @courses.each do |course|
      Rails.logger.debug "  #{course.name}: $#{course.green_fee}"
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

  def compare
    location_ids = params[:location_ids]&.split(',')
    @locations = Location.includes(:courses, :reviews).where(id: location_ids)
    
    # Redirect to locations index if fewer than 2 locations selected
    if @locations.size < 2
      redirect_to locations_path, alert: 'Please select at least 2 locations to compare'
      return
    end
    
    # Limit to 2 locations for side-by-side comparison
    @locations = @locations.limit(2)
  end
end
