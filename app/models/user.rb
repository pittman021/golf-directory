class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable


  has_many :reviews, dependent: :destroy

  enum role: { user: 0, admin: 1 }
  
  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true
end
