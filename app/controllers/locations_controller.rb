# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_location, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :authorize_admin!, except: [:index, :show]

  def index
    @locations = Location.includes(:courses, :reviews).all.order(:name)
    
    # Filter by region if parameter present
    if params[:region].present?
      @locations = @locations.by_region(params[:region])
    end
    
    # Filter by state if parameter present
    if params[:state].present?
      @locations = @locations.by_state(params[:state])
    end
    
    # Handle multiple tags for filtering
    if params[:tags].present?
      if params[:tags].is_a?(Array)
        # Handle multiple selected tags
        @locations = @locations.where("tags && ARRAY[?]::varchar[]", params[:tags])
      else
        # Handle single tag (backward compatibility)
        @locations = @locations.by_tag(params[:tag])
      end
    end
    
    # Filter by budget if parameter present
    if params[:max_budget].present?
      @locations = @locations.by_budget(params[:max_budget].to_i)
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
    @courses = @location.courses.ordered_by_price.includes(:reviews)
    
    @reviews = Review.joins(:course)
                    .where(courses: { id: @location.course_ids })
                    .includes(:user, :course)
                    .order(created_at: :desc)
                    .limit(5)
    
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
                                 .near([@location.latitude, @location.longitude], 200)
                                 .limit(3)
    else
      @nearby_locations = Location.where.not(id: @location.id).limit(3)
    end

    # Add these debug lines temporarily
    puts "DEBUG: Map ID from credentials: #{Rails.application.credentials.google_maps_map_id}"
    puts "DEBUG: API Key from credentials: #{Rails.application.credentials.google_maps_map_id.present?}"
  end

  def compare
    location_ids = params[:location_ids]&.split(',') || []
    @locations = Location.includes(:courses).where(id: location_ids)
    
    # Redirect to locations index if fewer than 2 locations selected
    if @locations.size < 2
      redirect_to locations_path, alert: 'Please select at least 2 locations to compare'
      return
    end
    
    # Limit to 2 locations for side-by-side comparison
    @locations = @locations.limit(2)
  end

  # GET /locations/new
  def new
    @location = Location.new
  end

  # GET /locations/1/edit
  def edit
  end

  # POST /locations
  def create
    @location = Location.new(location_params)

    if @location.save
      # Attach featured image if present
      if params[:location][:featured_image].present?
        @location.featured_image.attach(params[:location][:featured_image])
      end
      
      redirect_to @location, notice: 'Location was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /locations/1
  def update
    if @location.update(location_params)
      # Attach featured image if present
      if params[:location][:featured_image].present?
        @location.featured_image.attach(params[:location][:featured_image])
      end
      
      redirect_to @location, notice: 'Location was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /locations/1
  def destroy
    @location.destroy
    redirect_to locations_url, notice: 'Location was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_location
      @location = Location.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def location_params
      params.require(:location).permit(
        :name, :description, :latitude, :longitude, 
        :region, :state, :country, :best_months, 
        :nearest_airports, :weather_info, :image_url,
        tags: []
      )
    end
    
    def authorize_admin!
      redirect_to root_path, alert: "You are not authorized to perform that action" unless current_user.admin?
    end
end
