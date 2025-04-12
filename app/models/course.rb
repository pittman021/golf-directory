# app/models/course.rb
class Course < ApplicationRecord
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
    validates :layout_tags, presence: true
    
    # Available layout tags for courses
    LAYOUT_TAGS = [
      'water holes',
      'elevation changes',
      'tree lined',
      'links style',
      'island greens',
      'bunkers',
      'dog legs',
      'narrow fairways',
      'wide fairways'
    ]

    # Callbacks to update location's average green fee
    after_save :update_locations_avg_green_fee
    after_destroy :update_locations_avg_green_fee

    # Scope to order courses by price
    scope :ordered_by_price, -> { order(green_fee: :desc) }

    def average_rating
      reviews.average(:rating)
    end

    def featured_image_url
      if featured_image.attached?
        Rails.application.routes.url_helpers.rails_blob_url(featured_image, only_path: true)
      else
        # Default placeholder image
        ActionController::Base.helpers.asset_path('placeholder_golf_course.jpg')
      end
    end

    def featured_image_variant(size: 'medium')
      return unless featured_image.attached?

      case size
      when 'thumbnail'
        featured_image.variant(resize_to_fill: [150, 150])
      when 'small'
        featured_image.variant(resize_to_fill: [300, 200])
      when 'medium'
        featured_image.variant(resize_to_fill: [600, 400])
      when 'large'
        featured_image.variant(resize_to_fill: [1200, 800])
      else
        featured_image
      end
    end

    private

    def update_locations_avg_green_fee
      locations.each do |location|
        location.send(:update_avg_green_fee)
      end
    end
  end
