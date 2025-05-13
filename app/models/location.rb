# app/models/location.rb
class Location < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: [:slugged, :finders, :history]
    
    has_many :location_courses, dependent: :destroy
    has_many :courses, through: :location_courses
    has_many :reviews, through: :courses
    # has_one_attached :featured_image # Removed
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
    after_create :update_tags_from_courses!

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
    end

    # Calculate estimated trip cost (3 nights lodging + 3 rounds of golf)
    def calculate_estimated_trip_cost
      return unless avg_lodging_cost_per_night.present? && avg_green_fee.present?
      lodging_cost = avg_lodging_cost_per_night * 3
      golf_cost = avg_green_fee * 3
      self.estimated_trip_cost = lodging_cost + golf_cost
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

    def lodging_price_range
      return nil unless lodging_price_min && lodging_price_max
      "#{lodging_price_currency} #{lodging_price_min} - #{lodging_price_max}"
    end
    
    def has_lodging_data?
      (lodging_price_min.present? && lodging_price_max.present?) || avg_lodging_cost_per_night.present?
    end

    def image_with_transformation(options = {})
      return DEFAULT_IMAGE_URL if image_url.blank?
      
      # If already a Cloudinary URL, add transformation
      if image_url.include?('cloudinary')
        # Start with the base URL before any transformations
        base_url = image_url.split('/upload/').first + '/upload/'
        
        # Extract the file path part after upload/
        file_path = image_url.split('/upload/').last
        
        # Remove any existing transformations
        if file_path.include?('/')
          file_path = file_path.split('/').last
        end
        
        # Build transformation string
        transformations = []
        transformations << "w_#{options[:width]}" if options[:width]
        transformations << "h_#{options[:height]}" if options[:height]
        transformations << "c_#{options[:crop]}" if options[:crop]
        transformations << "g_#{options[:gravity]}" if options[:gravity]
        transformations << "q_#{options[:quality]}" if options[:quality]
        
        if transformations.any?
          "#{base_url}#{transformations.join(',')}/#{file_path}"
        else
          image_url
        end
      else
        # Not a Cloudinary URL, return as is
        image_url
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
    
    # Tags that are manually set on the location
    def manual_tags
      tags - derived_tags
    end

    # Tags derived from course data
    def derived_tags
      [].tap do |rolled_up|
        course_tags = courses.flat_map(&:course_tags).uniq.compact

        rolled_up << "top_100_courses" if course_tags.include?("top_100")
        rolled_up << "pga_event_host" if course_tags.include?("pga_tour_host")
        rolled_up << "bucket_list" if course_tags.include?("bucket_list")
        rolled_up << "multiple_courses" if courses.size > 1
      end
    end

    # Merge manual and derived tags, and update the tags field
    def update_tags_from_courses!
      update_column(:tags, (manual_tags + derived_tags).uniq)
    end

    # Define which attributes can be searched with Ransack
    def self.ransackable_attributes(auth_object = nil)
      ["best_months", "country", "created_at", "description", "destination_overview", 
       "estimated_trip_cost", "golf_experience", "id", "latitude", "local_attractions", 
       "longitude", "name", "nearest_airports", "practical_tips", "region", "state", 
       "summary", "tags", "travel_information", "updated_at", "weather_info", "cloudinary_url"]
    end
    
    def self.ransackable_associations(auth_object = nil)
      ["courses", "location_courses", "lodgings"]
    end

    private
    
    def parse_summary
      return nil if summary.blank?
      
      begin
        JSON.parse(summary)
      rescue JSON::ParserError => e
        Rails.logger.error "Error parsing summary JSON: #{e.message}"
        nil
      end
    end
end