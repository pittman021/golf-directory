# app/models/location.rb
class Location < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders, :history]

  has_many :location_courses, dependent: :destroy
  has_many :courses, through: :location_courses
  has_many :reviews, through: :courses
  has_many :lodgings, dependent: :destroy

  validates :name, presence: true
  validates :latitude, presence: true, numericality: true
  validates :longitude, presence: true, numericality: true
  validates :name, :region, :state, presence: true
  validates :avg_lodging_cost_per_night, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  geocoded_by :full_address

  scope :by_region, ->(region) { where(region: region) }
  scope :by_state, ->(state) { where(state: state) }
  scope :by_tag, ->(tag) { where("? = ANY (tags)", tag) }
  scope :by_budget, ->(max_budget) { where("estimated_trip_cost <= ?", max_budget) }
  scope :by_trip_cost, ->(category) {
    case category
    when 'budget'
      where("estimated_trip_cost <= ?", 1500)
    when 'mid_range'
      where("estimated_trip_cost > ? AND estimated_trip_cost <= ?", 1500, 2500)
    when 'premium'
      where("estimated_trip_cost > ? AND estimated_trip_cost <= ?", 2500, 4000)
    when 'luxury'
      where("estimated_trip_cost > ?", 4000)
    else
      all
    end
  }

  before_save :calculate_estimated_trip_cost
  after_save :update_avg_green_fee
  after_create :update_tags_from_courses!

  VIBES = %w[coastal scenic\ views resort\ style desert\ golf lake\ access mountains]

  DEFAULT_IMAGE_URL = "https://res.cloudinary.com/demo/image/upload/golf_directory/placeholder_golf_course.jpg"

  def upload_image(file)
    return false unless file.respond_to?(:read)
    require 'cloudinary'

    begin
      unless Cloudinary.config.cloud_name
        Cloudinary.config do |config|
          config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
          config.api_key = ENV['CLOUDINARY_API_KEY']
          config.api_secret = ENV['CLOUDINARY_API_SECRET']
          config.secure = true
        end
      end

      result = Cloudinary::Uploader.upload(file, folder: "golf_directory/locations", public_id: "#{id}-#{name.parameterize}", overwrite: true, resource_type: "auto")
      update(image_url: result['secure_url'])
      true
    rescue => e
      Rails.logger.error "Error uploading image to Cloudinary: #{e.message}"
      false
    end
  end

  def full_address
    [region, state, country].compact.join(', ')
  end

  def average_rating
    reviews.average(:rating)&.round(1)
  end

  def reviews_count
    @reviews_count ||= reviews.size
  end

  def courses_count
    @courses_count ||= courses.size
  end

  def avg_green_fee
    @avg_green_fee ||= begin
      return 0 if courses.empty?
      courses.average(:green_fee).to_i
    end
  end

  def estimated_trip_cost
    @estimated_trip_cost ||= begin
      return unless avg_lodging_cost_per_night.present? && avg_green_fee.present?
      avg_lodging_cost_per_night * 3 + avg_green_fee * 3
    end
  end

  def destination_overview
    parse_summary&.dig('destination_overview')
  end

  def golf_experience
    parse_summary&.dig('golf_experience')
  end

  def travel_information
    parse_summary&.dig('travel_information')
  end

  def local_attractions
    parse_summary&.dig('local_attractions')
  end

  def practical_tips
    parse_summary&.dig('practical_tips')
  end

  def lodging_price_range
    return nil unless lodging_price_min && lodging_price_max
    "#{lodging_price_currency} #{lodging_price_min} - #{lodging_price_max}"
  end

  def has_lodging_data?
    (lodging_price_min.present? && lodging_price_max.present?) || avg_lodging_cost_per_night.present?
  end

  def image_with_transformation(options = {})
    return DEFAULT_IMAGE_URL if image_url.blank?
    return image_url unless image_url.include?('cloudinary')

    base_url = image_url.split('/upload/').first + '/upload/'
    file_path = image_url.split('/upload/').last.split('/').last

    transformations = []
    transformations << "w_#{options[:width]}" if options[:width]
    transformations << "h_#{options[:height]}" if options[:height]
    transformations << "c_#{options[:crop]}" if options[:crop]
    transformations << "g_#{options[:gravity]}" if options[:gravity]
    transformations << "q_#{options[:quality]}" if options[:quality]

    transformations.any? ? "#{base_url}#{transformations.join(',')}/#{file_path}" : image_url
  end

  def thumbnail_image
    image_with_transformation(width: 150, height: 150, crop: 'fill')
  end

  def small_image
    image_with_transformation(width: 300, height: 200, crop: 'fill')
  end

  def medium_image
    image_with_transformation(width: 600, height: 400, crop: 'fill')
  end

  def large_image
    image_with_transformation(width: 1200, height: 800, crop: 'fill')
  end

  def stored_tags
    self[:tags] || []
  end
  
  def manual_tags
    stored_tags - derived_tags
  end
  
  def tags
    @tags ||= (manual_tags + derived_tags).uniq
  end

  def derived_tags
    [].tap do |rolled_up|
      course_tags = courses.flat_map(&:course_tags).uniq.compact
      rolled_up << "golf:top100" if course_tags.include?("top_100")
      rolled_up << "golf:tournament" if course_tags.include?("pga_tour_host")
      rolled_up << "golf:bucket_list" if course_tags.include?("bucket_list")
      rolled_up << "golf:multiple_courses" if courses.size > 1
    end
  end

  def update_tags_from_courses!
    combined = (manual_tags + derived_tags).uniq
    update_column(:tags, combined)
  end

  def tags_for(namespace)
    tags.select { |tag| tag.start_with?("#{namespace}:") }
  end

  def golf_tags
    @golf_tags ||= tags_for("golf")
  end

  def style_tags
    @style_tags ||= tags_for("style")
  end

  def has_tag?(tag)
    tags.include?(tag)
  end

  def has_any_tags?(*tag_list)
    (tags & tag_list.flatten).any?
  end

  scope :with_tag, ->(tag) { where("? = ANY(tags)", tag) }
  scope :with_any_tags, ->(tag_list) { where("tags && ARRAY[?]::varchar[]", tag_list) }

  def self.ransackable_attributes(auth_object = nil)
    %w[best_months country created_at description destination_overview estimated_trip_cost golf_experience id latitude local_attractions longitude name nearest_airports practical_tips region state summary tags travel_information updated_at weather_info cloudinary_url]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[courses location_courses lodgings]
  end

  private

  def parse_summary
    return if summary.blank?
  
    case summary
    when Hash
      summary
    when String
      begin
        JSON.parse(summary)
      rescue JSON::ParserError => e
        Rails.logger.error "Error parsing summary JSON: #{e.message}"
        nil
      end
    else
      nil
    end
  end

end
