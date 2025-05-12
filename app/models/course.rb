# app/models/course.rb
class Course < ApplicationRecord
    extend FriendlyId
    friendly_id :name, use: [:slugged, :finders, :history]
    
    has_many :location_courses, dependent: :destroy
    has_many :locations, through: :location_courses
    has_many :reviews, dependent: :destroy
    has_many_attached :images
    has_one_attached :featured_image
    
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
    validates :course_tags, presence: true
    
    # Set a default image URL for when none is provided
    DEFAULT_IMAGE_URL = "https://res.cloudinary.com/demo/image/upload/golf_directory/placeholder_golf_course.jpg"

    # Callbacks to update location's average green fee
    after_save :update_locations_avg_green_fee
    after_save :update_locations_tags
    after_destroy :update_locations_avg_green_fee
    after_destroy :update_locations_tags

    # Scope to order courses by price
    scope :ordered_by_price, -> { order(green_fee: :desc) }

    def average_rating
      reviews.average(:rating)
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

    # Define which attributes can be searched with Ransack
    def self.ransackable_attributes(auth_object = nil)
      ["course_tags", "course_type", "created_at", "description", "green_fee", "green_fee_range", 
       "id", "latitude", "longitude", "name", "notes", "number_of_holes", "par", 
       "updated_at", "website_url", "yardage", "cloudinary_url"]
    end
    
    def self.ransackable_associations(auth_object = nil)
      ["location", "reviews"]
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
