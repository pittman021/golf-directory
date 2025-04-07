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
end
