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
  end