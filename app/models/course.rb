# app/models/course.rb
class Course < ApplicationRecord
    has_many :location_courses, dependent: :destroy
    has_many :locations, through: :location_courses
    has_many :reviews, dependent: :destroy
    has_many_attached :images
    
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

    def average_rating
      reviews.average(:rating)
    end

    private

    def update_locations_avg_green_fee
      locations.each do |location|
        location.send(:update_avg_green_fee)
      end
    end
  end
