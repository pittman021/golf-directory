# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    @locations = Location.all
      .includes(:courses, :reviews)  # Keep the includes for optimization
      .left_joins(:reviews)  # Add left join to include locations without reviews
      .group('locations.id')  # Group by location to calculate average
      .select('locations.*, COALESCE(AVG(reviews.rating), 0) as avg_rating')  # Calculate average rating
      .order('avg_rating DESC, locations.name')  # Sort by average rating, then name
    
    # Apply filters
    @locations = @locations.where(country: params[:country]) if params[:country].present?
    @locations = filter_by_price_range(@locations) if params[:price_range].present?
    @locations = filter_by_season(@locations) if params[:season].present?
    
    # Paginate
    @locations = @locations.page(params[:page]).per(10)
  end

  private

  def filter_by_price_range(locations)
    case params[:price_range]
    when '0-50'
      locations.joins(:courses).where('courses.green_fee_range = ?', '$')
    when '51-150'
      locations.joins(:courses).where('courses.green_fee_range = ?', '$$')
    when '150-plus'
      locations.joins(:courses).where('courses.green_fee_range = ?', '$$$')
    else
      locations
    end
  end

  def filter_by_season(locations)
    locations.where('best_months LIKE ?', "%#{params[:season]}%")
  end
end