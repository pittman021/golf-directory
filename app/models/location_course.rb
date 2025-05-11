# app/models/location_course.rb
class LocationCourse < ApplicationRecord
  belongs_to :location
  belongs_to :course
  
  validates :location_id, uniqueness: { scope: :course_id }

  # Define which attributes can be searched with Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "created_at", "id", "location_id", "updated_at"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["course", "location"]
  end
end
