# app/controllers/courses_controller.rb
class CoursesController < ApplicationController
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
    
    # Set SEO meta tags
    @page_title = "Top 100 Golf Courses – Best Golf Destinations"
    @page_description = "Discover the best golf courses in the world. Our curated list of top 100 golf courses features championship venues, bucket list destinations, and premier golf experiences."
  end

  # GET /courses/1
  def show
    @reviews = @course.reviews.order(created_at: :desc).includes(:user)
    @review = Review.new(course: @course)

    # Set SEO meta tags
    @page_title = "#{@course.name} – Green Fees, Yardage, Course Info"
    @page_description = @course.description.present? ? @course.description.truncate(155) : "Play #{@course.name}, a #{@course.course_type.humanize} golf course in #{@course.locations.first.name}. #{@course.number_of_holes} holes, par #{@course.par}, green fee #{number_to_currency(@course.green_fee)}."
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
        @course = Course.friendly.find(params[:slug])
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
