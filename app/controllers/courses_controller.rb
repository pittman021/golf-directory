# app/controllers/courses_controller.rb
class CoursesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  before_action :set_course, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show, :top_100]
  before_action :authorize_admin!, except: [:index, :show, :top_100]

  # GET /courses
  def index
    @courses = Course.all.includes(:reviews, :locations).order(:name)
  end

  # GET /top-100-courses
  def top_100
    @courses = Course.where("'top_100_courses' = ANY(course_tags)")
                    .includes(:reviews, :locations, :state)
                    .order(:name)

    relevant_courses_for_average = @courses.where.not(green_fee: nil)
    if relevant_courses_for_average.any?
      @average_top_100_green_fee = relevant_courses_for_average.average(:green_fee)
    else
      @average_top_100_green_fee = nil
    end
    
    # Set SEO meta tags
    @page_title = "Top 100 Golf Courses – Best Golf Destinations"
    @page_description = "Discover the best golf courses in the world. Our curated list of top 100 golf courses features championship venues, bucket list destinations, and premier golf experiences."
  end

  # GET /courses/1
  def show
    @reviews = @course.reviews.order(created_at: :desc).includes(:user)
    @review = Review.new(course: @course)

    # Load nearby courses efficiently (moved from view)
    if @course.locations.any?
      @nearby_courses = Course.joins(:location_courses)
                             .where(location_courses: { location_id: @course.location_ids })
                             .where.not(id: @course.id)
                             .includes(:state)
                             .limit(6)
    else
      @nearby_courses = Course.none
    end

    # Set SEO meta tags
    @page_title = "#{@course.name} – Green Fees, Yardage, Course Info"
    
    # Build meta description with safe navigation and fallbacks
    description_parts = []
    description_parts << "Play #{@course.name}"
    description_parts << "a #{@course.course_type&.humanize || 'golf'} course"
    description_parts << "in #{@course.state&.name || 'the United States'}"
    
    course_details = []
    course_details << "#{@course.number_of_holes || '18'} holes" if @course.number_of_holes
    course_details << "par #{@course.par}" if @course.par
    course_details << "green fee #{number_to_currency(@course.green_fee)}" if @course.green_fee
    
    description_parts << course_details.join(', ') if course_details.any?
    
    @page_description = description_parts.join(', ') + '.'
  end

  # GET /courses/new
  def new
    @course = Course.new
    @locations = Location.all.order(:name)
  end

  # GET /courses/1/edit
  def edit
    @locations = Location.all.order(:name)
  end

  # POST /courses
  def create
    @course = Course.new(course_params)

    if @course.save
      # Handle location associations
      if params[:course][:location_ids].present?
        @course.location_ids = params[:course][:location_ids]
      end
      
      # Attach featured image if present
      if params[:course][:featured_image].present?
        @course.featured_image.attach(params[:course][:featured_image])
      end
      
      redirect_to @course, notice: 'Course was successfully created.'
    else
      @locations = Location.all.order(:name)
      render :new
    end
  end

  # PATCH/PUT /courses/1
  def update
    if @course.update(course_params)
      # Handle location associations
      if params[:course][:location_ids].present?
        @course.location_ids = params[:course][:location_ids]
      end
      
      # Attach featured image if present
      if params[:course][:featured_image].present?
        @course.featured_image.attach(params[:course][:featured_image])
      end
      
      redirect_to @course, notice: 'Course was successfully updated.'
    else
      @locations = Location.all.order(:name)
      render :edit
    end
  end

  # DELETE /courses/1
  def destroy
    @course.destroy
    redirect_to courses_url, notice: 'Course was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course
      if params[:slug].match?(/^\d+$/)
        # If the slug is a number, find by ID and redirect to the slug
        course = Course.find(params[:slug])
        redirect_to course_path(course), status: :moved_permanently
      else
        begin
          @course = Course.includes(:state, :reviews, location_courses: :location).friendly.find(params[:slug])
        rescue => e
          Rails.logger.error "Error finding course: #{e.message}"
          flash[:alert] = "Course not found"
          redirect_to courses_path
        end
      end
    end

    # Only allow a trusted parameter "white list" through.
    def course_params
      params.require(:course).permit(
        :name, :description, :green_fee, :par, :length,
        :image_url, :location_id, :tags
      )
    end
    
    def authorize_admin!
      redirect_to root_path, alert: "You are not authorized to perform that action" unless current_user.admin?
    end
end
