# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
    @locations = Location.all
      .includes(:courses, :reviews)  # Keep the includes for optimization
      .left_joins(:reviews)  # Add left join to include locations without reviews
      .group('locations.id')  # Group by location to calculate average
      .select('locations.*, COALESCE(AVG(reviews.rating), 0) as avg_rating')  # Calculate average rating

    # Get counts for stats
    @stats = {
      locations_count: Location.count,
      courses_count: Course.count,
      reviews_count: Review.count
    }

    # Apply filters
    @locations = @locations.where(region: params[:region]) if params[:region].present?
    @locations = @locations.where(state: params[:state]) if params[:state].present?
    
    # Filter by price category
    if params[:price_category].present?
      case params[:price_category]
      when 'budget'
        @locations = @locations.where('estimated_trip_cost <= ?', 1500)
      when 'mid_range'
        @locations = @locations.where('estimated_trip_cost > ? AND estimated_trip_cost <= ?', 1500, 2500)
      when 'premium'
        @locations = @locations.where('estimated_trip_cost > ? AND estimated_trip_cost <= ?', 2500, 4000)
      when 'luxury'
        @locations = @locations.where('estimated_trip_cost > ?', 4000)
      end
    end

    # Apply sorting
    @locations = apply_sorting(@locations)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def apply_sorting(locations)
    sort_column = params[:sort]
    sort_direction = params[:direction] == 'desc' ? 'desc' : 'asc'

    case sort_column
    when 'avg_green_fee'
      locations.order("avg_green_fee #{sort_direction}, name")
    when 'avg_lodging'
      locations.order("avg_lodging_cost_per_night #{sort_direction}, name")
    when 'estimated_trip_cost'
      locations.order("estimated_trip_cost #{sort_direction}, name")
    else
      locations.order('avg_rating DESC, name')
    end
  end

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