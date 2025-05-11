# app/models/review.rb
class Review < ApplicationRecord
  belongs_to :user
  belongs_to :course
  
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :played_on, presence: true
  validates :course_condition, presence: true
  validates :comment, presence: true
  validates :user_id, uniqueness: { scope: [:course_id, :played_on],
    message: "can only write one review per course per day" }

  # Define which attributes can be searched with Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["comment", "course_condition", "course_id", "created_at", "id", 
     "played_on", "rating", "status", "updated_at", "user_id"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["course", "user"]
  end
end
