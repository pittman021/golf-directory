# app/controllers/courses_controller.rb
class CoursesController < ApplicationController
  before_action :set_course, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]
  before_action :authorize_admin!, except: [:index, :show]

  # GET /courses
  def index
    @courses = Course.all.includes(:reviews, :locations).order(:name)
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
      @course = Course.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def course_params
      params.require(:course).permit(
        :name, :description, :latitude, :longitude, 
        :course_type, :green_fee_range, :green_fee,
        :number_of_holes, :par, :yardage, :website_url, 
        :image_url, course_tags: []
      )
    end
    
    def authorize_admin!
      redirect_to root_path, alert: "You are not authorized to perform that action" unless current_user.admin?
    end
end
