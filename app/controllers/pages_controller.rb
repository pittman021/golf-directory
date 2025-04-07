# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    @locations = Location.all
      .includes(:courses, :reviews)  # Keep the includes for optimization
      .left_joins(:reviews)  # Add left join to include locations without reviews
      .group('locations.id')  # Group by location to calculate average
      .select('locations.*, COALESCE(AVG(reviews.rating), 0) as avg_rating')  # Calculate average rating

    # Apply filters
    @locations = @locations.where(region: params[:region]) if params[:region].present?
    @locations = @locations.where(state: params[:state]) if params[:state].present?
    
    if params[:price_range].present?
      @locations = @locations.joins(:courses)
        .group('locations.id')
        .having("MODE() WITHIN GROUP (ORDER BY courses.green_fee_range) = ?", params[:price_range])
    end

    @locations = @locations.order('avg_rating DESC, locations.name')

    respond_to do |format|
      format.html
      format.turbo_stream
    end
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