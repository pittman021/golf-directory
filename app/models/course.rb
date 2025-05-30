# app/models/course.rb
class Course < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: [:slugged, :finders, :history]
    
    has_many :location_courses, dependent: :destroy
    has_many :locations, through: :location_courses
    has_many :reviews, dependent: :destroy
    has_many_attached :images
    belongs_to :state
    
    enum course_type: {
      public_course: 0,
      private_course: 1,
      resort_course: 2
    }
    
    validates :name, presence: true
    validates :course_type, presence: true
    validates :number_of_holes, presence: true, inclusion: { in: [9, 18] }
    validates :par, presence: true, numericality: { only_integer: true }
    validates :yardage, presence: true, numericality: { only_integer: true }
    validates :green_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
    # validates :course_tags, presence: true  # Removed to allow cleanup
    validates :state_id, presence: true
    
    # Set a default image URL for when none is provided
    DEFAULT_IMAGE_URL = "https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=600&h=400&fit=crop"

    # Callbacks to update location's average green fee
    after_save :update_locations_avg_green_fee
    after_save :update_locations_tags
    after_destroy :update_locations_avg_green_fee
    after_destroy :update_locations_tags

    # Scope to order courses by price
    scope :ordered_by_price, -> { order(green_fee: :desc) }

    # Scope to find courses within a radius of given coordinates
    scope :nearby, ->(lat, lng, radius_meters = 50000) {
      where("earth_distance(ll_to_earth(latitude, longitude), ll_to_earth(?, ?)) <= ?", lat, lng, radius_meters)
    }

    # Scope to find courses with a specific tag (case-insensitive)
    scope :with_tag, ->(tag_name) {
      where("EXISTS (SELECT 1 FROM unnest(course_tags) AS t(tag_element) WHERE LOWER(t.tag_element) LIKE ?)", "%#{tag_name.downcase}%")
    }

    def average_rating
      reviews.average(:rating)
    end

    # Cloudinary helpers for direct URL transformations
    def image_with_transformation(options = {})
      # Return default image if image_url is blank or nil
      return DEFAULT_IMAGE_URL if image_url.blank?
      
      # Default transformations
      default_options = { width: 600, height: 400, crop: 'fill' }
      
      # Merge with provided options
      transform_options = default_options.merge(options)
      
      # Generate Cloudinary URL with transformations
      begin
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
      rescue URI::InvalidURIError, NoMethodError, ArgumentError => e
        # If URI parsing fails for any reason, log it and return the default image
        Rails.logger.error "Failed to parse image URL '#{image_url}' for course #{id}: #{e.message}"
        DEFAULT_IMAGE_URL
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

    # Define which attributes can be searched with Ransack
    def self.ransackable_attributes(auth_object = nil)
      ["course_tags", "course_type", "created_at", "description", "green_fee", "green_fee_range", 
       "id", "latitude", "longitude", "name", "notes", "number_of_holes", "par", 
       "updated_at", "website_url", "yardage", "image_url", "amenities", "phone"]
    end
    
    def self.ransackable_associations(auth_object = nil)
      ["location_courses", "locations", "reviews"]
    end

    # Amenities helper methods - now using standardized system
    def has_amenity?(amenity_name)
      amenities&.include?(amenity_name.to_s)
    end

    def amenities_by_category
      return {} unless amenities.present?
      
      require_relative '../config/standardized_amenities' unless defined?(StandardizedAmenityProcessor)
      StandardizedAmenityProcessor.categorize_amenities(amenities)
    end

    def standardized_amenities
      return [] unless amenities.present?
      
      require_relative '../config/standardized_amenities' unless defined?(StandardizedAmenityProcessor)
      StandardizedAmenityProcessor.standardize_amenities(amenities)
    end

    def amenity_count
      amenities&.length || 0
    end

    # Check if course has amenities in a specific category
    def has_golf_facilities?
      golf_facilities = ['Driving Range', 'Putting Green', 'Short Game Area', 'Practice Facility']
      amenities.present? && (amenities & golf_facilities).any?
    end

    def has_dining?
      dining_amenities = ['Restaurant', 'Bar', 'Snack Bar', 'Beverage Cart']
      amenities.present? && (amenities & dining_amenities).any?
    end

    def has_lodging?
      amenities&.include?('Lodging')
    end

    def has_event_facilities?
      event_amenities = ['Event Space', 'Tournament Host', 'Wedding Venue', 'Conference Facilities', 'Banquet Facilities']
      amenities.present? && (amenities & event_amenities).any?
    end

    private

    def update_locations_avg_green_fee
      locations.each do |location|
        location.send(:update_avg_green_fee)
      end
    end
    
    def update_locations_tags
      locations.each do |location|
        location.update_tags_from_courses!
      end
    end
  end
