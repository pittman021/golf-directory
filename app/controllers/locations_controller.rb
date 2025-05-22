# app/controllers/locations_controller.rb
class LocationsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_location, only: [:show, :edit, :update, :destroy]

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
    @courses = @location.courses.ordered_by_price.includes(:reviews, :state)
    
    @reviews = Review.joins(:course)
                    .where(courses: { id: @location.course_ids })
                    .includes(:user, :course)
                    .order(created_at: :desc)
                    .limit(5)

    # Get nearby courses if coordinates are available
    if @location.latitude && @location.longitude
      @nearby_courses = Course.nearby(@location.latitude, @location.longitude, 80467) # 50 miles in meters
                             .where.not(id: @location.course_ids)
                             .includes(:reviews, :state)
                             .limit(10)
    else
      @nearby_courses = Course.where.not(id: @location.course_ids).limit(10)
    end

    # Get nearby locations if coordinates are available
    if @location.latitude && @location.longitude
      @nearby_locations = Location.where.not(id: @location.id)
                                 .near([@location.latitude, @location.longitude], 200)
                                 .limit(3)
    else
      @nearby_locations = Location.where.not(id: @location.id).limit(3)
    end

    # Set SEO meta tags
    @page_title = "Golf in #{@location.name} – Courses, Lodging & Trip Costs"
    @page_description = @location.destination_overview.present? ? @location.destination_overview.truncate(155) : "Discover golf courses, lodging options, and trip costs in #{@location.name}. Plan your perfect golf getaway with detailed information about courses, accommodations, and local attractions."
  end

  def compare
    # Parse location IDs from the params, ensuring they are integers
    location_ids = if params[:location_ids].present?
                    params[:location_ids].split(',').map(&:to_i).uniq
                  else
                    []
                  end
    
    # Find the locations, including their courses
    @locations = Location.includes(:courses).where(id: location_ids)
    
    # Redirect to locations index if fewer than 2 locations selected
    if @locations.size < 2
      redirect_to locations_path, alert: 'Please select at least 2 locations to compare'
      return
    end
    
    # Take the first 2 locations for side-by-side comparison
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
      if params[:slug].match?(/^\d+$/)
        # If the slug is a number, find by ID and redirect to the slug
        location = Location.find(params[:slug])
        redirect_to location_path(location), status: :moved_permanently
      else
        @location = Location.friendly.find(params[:slug])
      end
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
