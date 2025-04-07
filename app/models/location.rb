# app/models/location.rb
class Location < ApplicationRecord
    has_many :location_courses, dependent: :destroy
    has_many :courses, through: :location_courses
    has_many :reviews, through: :courses
    
    validates :name, presence: true
    validates :latitude, presence: true, numericality: true
    validates :longitude, presence: true, numericality: true
    
    geocoded_by :full_address
    
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
      courses.group(:green_fee_range).count.max_by { |_, v| v }&.first || 'N/A'
    end
    
    def courses_count
      courses.count
    end
  end