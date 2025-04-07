# app/controllers/courses_controller.rb
class CoursesController < ApplicationController
  def index
    @location = Location.find(params[:location_id])
    @courses = @location.courses
  end

  def show
    @course = Course.find(params[:id])
    @reviews = @course.reviews.includes(:user).order(created_at: :desc)
    @review = Review.new if user_signed_in?
  end
end
