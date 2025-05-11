class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  has_many :reviews, dependent: :destroy

  enum role: { user: 0, admin: 1 }
  
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  # Define which attributes can be searched with Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email", "id", "role", "updated_at", "username"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["reviews"]
  end
end
