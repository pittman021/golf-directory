# app/models/location_course.rb
class LocationCourse < ApplicationRecord
  belongs_to :location
  belongs_to :course
  
  validates :location_id, uniqueness: { scope: :course_id }
end
