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
    
    def average_rating
      reviews.average(:rating)
    end
  end
