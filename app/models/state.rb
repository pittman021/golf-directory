class State < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [:slugged, :finders, :history]

  # Associations
  has_many :courses
  has_many :locations, -> { distinct }, through: :courses

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  # Scopes
  scope :with_featured_courses, -> { where("array_length(featured_course_ids, 1) > 0") }
  scope :with_featured_locations, -> { where("array_length(featured_location_ids, 1) > 0") }

  # Methods
  def courses_count
    @courses_count ||= courses.count
  end

  def top_100_courses_count
    @top_100_courses_count ||= courses.with_tag("golf:top100").count
  end

  def featured_courses
    Course.where(id: featured_course_ids)
  end

  def featured_locations
    Location.where(id: featured_location_ids)
  end

  def average_green_fee
    @average_green_fee ||= begin
      relevant_courses = courses.where.not(green_fee: nil)
      if relevant_courses.any?
        relevant_courses.average(:green_fee)
      else
        nil
      end
    end
  end

  def tags
    @tags ||= courses.flat_map(&:course_tags).uniq
  end

  def golf_tags
    @golf_tags ||= tags.select { |tag| tag.start_with?("golf:") }
  end

  def summary_section(key)
    summary&.dig(key)
  end

  # SEO methods
  def meta_title
    super || "#{name} Golf Courses & Destinations"
  end

  def meta_description
    super || "Discover the best golf courses and destinations in #{name}. Find top-rated courses, golf resorts, and plan your perfect golf trip."
  end

  # Summary section methods
  def practical_tips
    summary_section('practical_tips')
  end

  def golf_experience
    summary_section('golf_experience')
  end

  def local_attractions
    summary_section('local_attractions')
  end

  def travel_information
    summary_section('travel_information')
  end

  def destination_overview
    summary_section('destination_overview')
  end

  # Tag counting methods
  def tag_counts
    @tag_counts ||= begin
      counts = Hash.new(0)
      courses.each do |course|
        course.tags.each { |tag| counts[tag] += 1 }
      end
      counts
    end
  end

  def golf_tag_counts
    @golf_tag_counts ||= tag_counts.select { |tag, _| tag.start_with?("golf:") }
  end

  # Clear memoized values
  def clear_tag_cache
    @tags = nil
    @golf_tags = nil
    @tag_counts = nil
    @golf_tag_counts = nil
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[name slug description image_url best_months featured_course_ids featured_location_ids summary meta_title meta_description created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[courses locations]
  end
end 