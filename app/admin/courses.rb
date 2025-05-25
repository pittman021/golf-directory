ActiveAdmin.register Course do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name, :description, :latitude, :longitude, :course_type, :green_fee_range, :number_of_holes, :par, :yardage, :website_url, :course_tags, :notes, :green_fee, :image_url
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :description, :latitude, :longitude, :course_type, :green_fee_range, :number_of_holes, :par, :yardage, :website_url, :course_tags, :notes, :green_fee, :image_url]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  # Use slugs for finding records
  controller do
    defaults finder: :find_by_slug
    
    def update
      if params[:course][:location_ids].present?
        @course = Course.find_by_slug(params[:id])
        @course.locations = Location.where(id: params[:course][:location_ids].reject(&:blank?))
      end
      super
    end
    
    def create
      if params[:course][:location_ids].present?
        @course = Course.new(course_params)
        @course.locations = Location.where(id: params[:course][:location_ids].reject(&:blank?))
      end
      super
    end

    private

    def course_params
      params.require(:course).permit(:name, :course_type, :description, :green_fee, 
                                   :green_fee_range, :number_of_holes, :par, :yardage, 
                                   :notes, :website_url, :latitude, :longitude, 
                                   :image_url, course_tags: [])
    end
  end

  # Index page configuration
  index do
    selectable_column
    id_column
    column :name
    column "Location" do |course|
      course.locations.first&.name || "No location"
    end
    column :course_type
    column :green_fee do |course|
      number_to_currency(course.green_fee)
    end
    column :number_of_holes
    column :par
    column :yardage
    column "Rating" do |course|
      if course.average_rating.present?
        "#{course.average_rating} (#{course.reviews.count} reviews)"
      else
        "No ratings"
      end
    end
    actions
  end

  # Filters
  filter :name
  filter :locations_id_in, as: :select, collection: proc { Location.all.map { |l| [l.name, l.id] } }, label: 'Location'
  filter :course_type, as: :select, collection: Course.course_types.map { |k, v| [k.humanize, k] }
  filter :green_fee
  filter :course_tags
  filter :created_at

  # Form customization
  form do |f|
    f.inputs "Course Details" do
      f.input :name
      f.input :locations, as: :select, collection: Location.all.map { |l| [l.name, l.id] }, input_html: { multiple: true }, include_blank: false
      f.input :course_type, as: :select, collection: Course.course_types.map { |k, v| [k.humanize, k] }
      f.input :description
      f.input :green_fee
      f.input :green_fee_range
      f.input :number_of_holes
      f.input :par
      f.input :yardage
      f.input :course_tags, as: :check_boxes, collection: TAG_CATEGORIES.values.flatten.uniq.reject(&:blank?), label_method: :titleize
      f.input :notes
      f.input :website_url
      f.input :latitude
      f.input :longitude
      f.input :image_url
    end

    f.actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :name
      row :locations do |course|
        course.locations.map(&:name).join(", ")
      end
      row :course_type
      row :description
      row :green_fee do |course|
        number_to_currency(course.green_fee)
      end
      row :green_fee_range
      row :number_of_holes
      row :par
      row :yardage
      row :course_tags
      row :notes
      row :website_url do |course|
        if course.website_url.present?
          link_to course.website_url, course.website_url, target: "_blank"
        else
          "No website"
        end
      end
      row :latitude
      row :longitude
      row "Image" do |course|
        if course.image_url.present?
          image_tag course.image_url, style: 'max-width: 300px'
        else
          "No image"
        end
      end
      row :created_at
      row :updated_at
    end

    panel "Reviews (#{resource.reviews.count})" do
      table_for resource.reviews do
        column :id
        column :user
        column :rating
        column :comment
        column :created_at
        column :actions do |review|
          link_to "View", admin_review_path(review)
        end
      end
    end
  end

  # Permit all parameters
  permit_params :name, :location_id, :course_type, :description, :green_fee, 
                :green_fee_range, :number_of_holes, :par, :yardage, :notes, 
                :website_url, :latitude, :longitude, :image_url, course_tags: [], location_ids: []
end
