ActiveAdmin.register Location do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :name, :description, :latitude, :longitude, :region, :state, :country, :best_months, :nearest_airports, :weather_info, :reviews_count, :avg_green_fee, :avg_lodging_cost_per_night, :estimated_trip_cost, :tags, :summary, :lodging_price_min, :lodging_price_max, :lodging_price_currency, :lodging_price_last_updated, :image_url
  #
  # or
  #
  # permit_params do
  #   permitted = [:name, :description, :latitude, :longitude, :region, :state, :country, :best_months, :nearest_airports, :weather_info, :reviews_count, :avg_green_fee, :avg_lodging_cost_per_night, :estimated_trip_cost, :tags, :summary, :lodging_price_min, :lodging_price_max, :lodging_price_currency, :lodging_price_last_updated, :image_url]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  # Use slugs for finding records
  controller do
    defaults finder: :find_by_slug
    
    def update
      # Convert comma-separated tags to array
      if params[:location] && params[:location][:tags].present?
        params[:location][:tags] = params[:location][:tags].split(',').map(&:strip)
      end
      super
    end
    
    def create
      # Convert comma-separated tags to array
      if params[:location] && params[:location][:tags].present?
        params[:location][:tags] = params[:location][:tags].split(',').map(&:strip)
      end
      super
    end
  end

  # Configuration for the index page (list view)
  index do
    selectable_column
    id_column
    column :name
    column :state
    column :country
    column "Courses" do |location|
      location.courses.count
    end
    column "Avg. Green Fee" do |location|
      number_to_currency(location.avg_green_fee)
    end
    column :created_at
    actions
  end

  # Customize filters in sidebar
  filter :name
  filter :state
  filter :country
  filter :region
  filter :created_at

  # Customize the form - Simplified for production use
  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :region, as: :string
      f.input :state, as: :string
      f.input :country, as: :string
      f.input :latitude
      f.input :longitude
      f.input :best_months
      f.input :nearest_airports
      f.input :weather_info
      f.input :avg_green_fee
      f.input :avg_lodging_cost_per_night
      f.input :estimated_trip_cost
      f.input :tags, input_html: { value: f.object.tags&.join(', ') }
      f.input :summary
      f.input :lodging_price_min
      f.input :lodging_price_max
      f.input :lodging_price_currency
      f.input :lodging_price_last_updated
      f.input :image_url
    end
    
    f.actions
  end

  # Show page customization
  show do
    attributes_table do
      row :id
      row :name
      row :state
      row :country
      row :region
      row :tags
      row "Image" do |location|
        if location.image_url.present?
          image_tag location.image_url, style: 'max-width: 300px'
        else
          "No image"
        end
      end
      
      # Display summary in sections if available
      panel "Content Sections" do
        tabs do
          tab "Summary" do
            div do
              pre location.summary
            end
          end
          
          if location.respond_to?(:destination_overview) && location.destination_overview.present?
            tab "Destination Overview" do
              div do
                pre location.destination_overview
              end
            end
          end
          
          if location.respond_to?(:golf_experience) && location.golf_experience.present?
            tab "Golf Experience" do
              div do
                pre location.golf_experience
              end
            end
          end
          
          if location.respond_to?(:travel_information) && location.travel_information.present?
            tab "Travel Information" do
              div do
                pre location.travel_information
              end
            end
          end
          
          if location.respond_to?(:local_attractions) && location.local_attractions.present?
            tab "Local Attractions" do
              div do
                pre location.local_attractions
              end
            end
          end
          
          if location.respond_to?(:practical_tips) && location.practical_tips.present?
            tab "Practical Tips" do
              div do
                pre location.practical_tips
              end
            end
          end
        end
      end
      
      row :description
      row :weather_info
      row :best_months
      row :nearest_airports
      row :latitude
      row :longitude
      row :estimated_trip_cost do |location|
        number_to_currency(location.estimated_trip_cost)
      end
      row :avg_green_fee do |location|
        number_to_currency(location.avg_green_fee)
      end
      row :avg_lodging_cost_per_night do |location|
        number_to_currency(location.avg_lodging_cost_per_night)
      end
      row :lodging_price_min do |location|
        number_to_currency(location.lodging_price_min)
      end
      row :lodging_price_max do |location|
        number_to_currency(location.lodging_price_max)
      end
      row :lodging_price_currency
      row :created_at
      row :updated_at
    end

    panel "Courses (#{resource.courses.count})" do
      table_for resource.courses do
        column :id
        column :name
        column :course_type
        column :green_fee do |course|
          number_to_currency(course.green_fee)
        end
        column :actions do |course|
          link_to "View", admin_course_path(course)
        end
      end
    end

    panel "Lodgings (#{resource.lodgings.count})" do
      table_for resource.lodgings do
        column :id
        column :name
        column :address
        column :website
        column :actions do |lodging|
          link_to "View", admin_lodging_path(lodging)
        end
      end
    end
  end

  # Permit parameters
  permit_params :name, :state, :country, :region, :summary, :description,
                :weather_info, :best_months, :nearest_airports, :latitude, :longitude,
                :estimated_trip_cost, :avg_green_fee, :avg_lodging_cost_per_night,
                :lodging_price_min, :lodging_price_max, :lodging_price_currency,
                :image_url, :tags
end
