# app/models/location.rb
class Location < ApplicationRecord
    has_many :location_courses, dependent: :destroy
    has_many :courses, through: :location_courses
    has_many :reviews, through: :courses
    has_one_attached :featured_image
    has_many :lodgings, dependent: :destroy
    
    validates :name, presence: true
    validates :latitude, presence: true, numericality: true
    validates :longitude, presence: true, numericality: true
    
    geocoded_by :full_address
    
    # Validations
    validates :name, :region, :state, presence: true
    validates :avg_lodging_cost_per_night, 
              numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

    # Scopes for filtering
    scope :by_region, ->(region) { where(region: region) }
    scope :by_state, ->(state) { where(state: state) }
    scope :by_tag, ->(tag) { where("? = ANY (tags)", tag) }
    scope :by_budget, ->(max_budget) { where("estimated_trip_cost <= ?", max_budget) }

    before_save :calculate_estimated_trip_cost
    after_save :update_avg_green_fee

    # Available vibes for filtering
    VIBES = [
      'coastal',
      'scenic views',
      'resort style',
      'desert golf',
      'lake access',
      'mountains'
    ]

    # Set a default image URL for when none is provided
    DEFAULT_IMAGE_URL = "https://res.cloudinary.com/demo/image/upload/golf_directory/placeholder_golf_course.jpg"

    # Update image_url directly with a Cloudinary URL
    def update_image_url(url)
      update(image_url: url)
    end

    # Upload an image file directly to Cloudinary and store the URL
    def upload_image(file)
      return false unless file.respond_to?(:read)
      
      require 'cloudinary'
      
      begin
        # Configure Cloudinary if needed
        unless Cloudinary.config.cloud_name
          Cloudinary.config do |config|
            config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
            config.api_key = ENV['CLOUDINARY_API_KEY']
            config.api_secret = ENV['CLOUDINARY_API_SECRET']
            config.secure = true
          end
        end
        
        # Upload the image to Cloudinary
        result = Cloudinary::Uploader.upload(file, 
          folder: "golf_directory/locations",
          public_id: "#{self.id}-#{self.name.parameterize}",
          overwrite: true,
          resource_type: "auto"
        )
        
        # Store the URL in the image_url field
        update(image_url: result['secure_url'])
        true
      rescue => e
        Rails.logger.error "Error uploading image to Cloudinary: #{e.message}"
        false
      end
    end

    def full_address
      [region, state, country].compact.join(', ')
    end
    
    def average_rating
      reviews.average(:rating)&.round(1)
    end
    
    def reviews_count
      reviews.count
    end
    
    def average_price_range
      return nil if courses.empty?
      
      # Convert price ranges to numbers
      price_values = courses.map do |course|
        case course.green_fee_range
        when '$' then 1
        when '$$' then 2
        when '$$$' then 3
        when '$$$$' then 4
        else 0
        end
      end
      
      # Calculate average and convert back to symbols
      avg = price_values.sum.to_f / price_values.size
      case avg
      when 0..1.5 then '$'
      when 1.5..2.5 then '$$'
      when 2.5..3.5 then '$$$'
      else '$$$$'
      end
    end
    
    def courses_count
      courses.count
    end

    def avg_green_fee
      return 0 if courses.empty?
      courses.average(:green_fee).to_i
    end
    
    def price_category
      return { symbol: '-', label: 'N/A' } if estimated_trip_cost.nil?
      
      case estimated_trip_cost
      when 0..1500
        { symbol: '$', label: 'Budget' }
      when 1501..2500
        { symbol: '$$', label: 'Mid-Range' }
      when 2501..4000
        { symbol: '$$$', label: 'Premium' }
      else
        { symbol: '$$$$', label: 'Luxury' }
      end
    end
    
    def update_avg_green_fee
      # This ensures the average is updated whenever courses are added/modified
      current_avg = avg_green_fee
      update_column(:avg_green_fee, current_avg) unless avg_green_fee == current_avg
      calculate_and_update_trip_cost
    end

    def calculate_and_update_trip_cost
      return unless avg_lodging_cost_per_night.present?
      lodging_cost = avg_lodging_cost_per_night * 3
      golf_cost = avg_green_fee * 3
      new_total = lodging_cost + golf_cost
      update_column(:estimated_trip_cost, new_total) unless estimated_trip_cost == new_total
    end

    # Get URL for featured image
    def featured_image_url
      return image_url if image_url.present?
      return nil unless featured_image.attached?
      
      begin
        # Use ActiveStorage's URL generation
        Rails.application.routes.url_helpers.url_for(featured_image)
      rescue StandardError => e
        Rails.logger.error "Error generating URL for featured image: #{e.message}"
        nil
      end
    end

    # Generate a variant of the featured image
    def featured_image_variant(size = 'medium')
      return nil unless featured_image.attached?
      
      transformation = case size
                       when 'thumbnail'
                         { resize_to_fill: [150, 150] }
                       when 'small'
                         { resize_to_fill: [300, 200] }
                       when 'medium'
                         { resize_to_fill: [600, 400] }
                       when 'large'
                         { resize_to_fill: [1200, 800] }
                       else
                         { resize_to_fill: [600, 400] }
                       end
      
      # Create the variant
      featured_image.variant(transformation).processed
    end

    def destination_overview
      parse_summary&.dig('destination_overview')
    end

    def golf_experience
      parse_summary&.dig('golf_experience')
    end

    def travel_information
      parse_summary&.dig('travel_information')
    end

    def local_attractions
      parse_summary&.dig('local_attractions')
    end

    def practical_tips
      parse_summary&.dig('practical_tips')
    end

    def update_avg_lodging_cost
      return if lodgings.empty?
      
      total_avg = lodgings.sum(&:average_price)
      count = lodgings.count
      
      update(avg_lodging_cost_per_night: total_avg / count)
    end

    def lodging_price_range
      return nil unless lodging_price_min && lodging_price_max
      "#{lodging_price_currency} #{lodging_price_min} - #{lodging_price_max}"
    end
    
    def update_lodging_prices(min:, max:, source:, notes: nil)
      update(
        lodging_price_min: min,
        lodging_price_max: max,
        lodging_price_source: source,
        lodging_price_notes: notes,
        lodging_price_last_updated: Time.current
      )
    end
    
    def average_lodging_price
      return nil unless lodging_price_min && lodging_price_max
      (lodging_price_min + lodging_price_max) / 2.0
    end

    def calculate_estimated_trip_cost
      return unless average_lodging_price.present? && avg_green_fee.present?
      # 3 nights lodging + 3 rounds of golf
      lodging_cost = average_lodging_price * 3
      golf_cost = avg_green_fee * 3
      self.estimated_trip_cost = lodging_cost + golf_cost
    end

    def avg_lodging_cost_per_night
      return nil unless lodging_price_min && lodging_price_max
      (lodging_price_min + lodging_price_max) / 2
    end

    def has_lodging_data?
      lodging_price_min.present? && lodging_price_max.present?
    end

    # Cloudinary helpers for direct URL transformations
    def image_with_transformation(options = {})
      return DEFAULT_IMAGE_URL if image_url.blank?
      
      # Default transformations
      default_options = { width: 600, height: 400, crop: 'fill' }
      
      # Merge with provided options
      transform_options = default_options.merge(options)
      
      # Generate Cloudinary URL with transformations
      if image_url.include?('cloudinary')
        # Parse existing URL and add transformations
        uri = URI.parse(image_url)
        path_parts = uri.path.split('/')
        
        # Find upload part and insert transformations
        upload_index = path_parts.index('upload')
        if upload_index
          transform_string = transform_options.map { |k, v| "#{k}_#{v}" }.join(',')
          path_parts.insert(upload_index + 1, transform_string)
          uri.path = path_parts.join('/')
          uri.to_s
        else
          image_url # Return original if we can't parse
        end
      else
        image_url # Return original for non-Cloudinary URLs
      end
    end
    
    def thumbnail_image
      image_with_transformation(width: 150, height: 150, crop: 'fill')
    end
    
    def small_image
      image_with_transformation(width: 300, height: 200, crop: 'fill')
    end
    
    def medium_image
      image_with_transformation(width: 600, height: 400, crop: 'fill')
    end
    
    def large_image
      image_with_transformation(width: 1200, height: 800, crop: 'fill')
    end

    # Get Cloudinary URL directly for featured image
    def cloudinary_url
      # If image_url is already a Cloudinary URL, use it directly
      if image_url.present? && image_url.include?('cloudinary')
        image_url
      # Otherwise, try to get the featured image URL
      elsif featured_image.attached?
        begin
          # Use ActiveStorage URL generation
          Rails.application.routes.url_helpers.url_for(featured_image)
        rescue => e
          # If all else fails, use default image
          DEFAULT_IMAGE_URL
        end
      else
        # Default image as fallback
        DEFAULT_IMAGE_URL
      end
    end

    private

    def parse_summary
      return nil if summary.blank?
      return summary if summary.is_a?(Hash)
      JSON.parse(summary) rescue nil
    end
  end