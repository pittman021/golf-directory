class Lodging < ApplicationRecord
  belongs_to :location
  
  validates :google_place_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  
  RESEARCH_STATUSES = %w[pending in_progress completed].freeze
  
  validates :research_status, inclusion: { in: RESEARCH_STATUSES }
  
  scope :featured, -> { where(is_featured: true) }
  scope :needs_research, -> { where(research_status: 'pending') }
  scope :by_rating, -> { order(rating: :desc) }
  
  has_one_attached :photo
  
  def start_price_research
    update(
      research_status: 'in_progress',
      research_last_attempted: Date.today,
      research_attempts: research_attempts + 1
    )
  end
  
  def complete_price_research(price_data)
    update(
      research_status: 'completed',
      research_notes: price_data[:research_notes]
    )
  end
  
  def download_photo
    return if photo_reference.blank? || photo.attached?

    # Construct the photo URL
    photo_url = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photo_reference=#{photo_reference}&key=#{Rails.application.credentials.google_maps[:api_key]}"
    
    # Download and attach the photo
    begin
      response = Net::HTTP.get_response(URI(photo_url))
      if response.is_a?(Net::HTTPSuccess)
        photo.attach(
          io: StringIO.new(response.body),
          filename: "#{name.parameterize}-photo.jpg",
          content_type: 'image/jpeg'
        )
      end
    rescue => e
      Rails.logger.error "Failed to download photo for #{name}: #{e.message}"
    end
  end
end 