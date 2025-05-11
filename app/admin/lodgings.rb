ActiveAdmin.register Lodging do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :google_place_id, :name, :types, :rating, :latitude, :longitude, :formatted_address, :formatted_phone_number, :website, :research_notes, :research_status, :research_last_attempted, :research_attempts, :location_id, :is_featured, :display_order, :photo_reference
  #
  # or
  #
  # permit_params do
  #   permitted = [:google_place_id, :name, :types, :rating, :latitude, :longitude, :formatted_address, :formatted_phone_number, :website, :research_notes, :research_status, :research_last_attempted, :research_attempts, :location_id, :is_featured, :display_order, :photo_reference]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  # Index page configuration
  index do
    selectable_column
    id_column
    column :name
    column :location
    column :address
    column :rating
    column :price_range
    column :lodging_type
    column :website do |lodging|
      if lodging.website.present?
        link_to "Website", lodging.website, target: "_blank"
      end
    end
    actions
  end

  # Filters
  filter :name
  filter :location, collection: proc { Location.all.map { |l| [l.name, l.id] } }
  filter :lodging_type
  filter :rating
  filter :created_at

  # Form customization
  form do |f|
    f.inputs "Lodging Details" do
      f.input :name
      f.input :location, collection: Location.all.map { |l| [l.name, l.id] }
      f.input :address
      f.input :formatted_address
      f.input :lodging_type
      f.input :description
      f.input :amenities
      f.input :rating
      f.input :price_range
      f.input :website
      f.input :latitude
      f.input :longitude
      f.input :phone
    end
    f.actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :name
      row :location
      row :address
      row :formatted_address
      row :lodging_type
      row :description
      row :amenities
      row :rating
      row :price_range
      row :website do |lodging|
        if lodging.website.present?
          link_to lodging.website, lodging.website, target: "_blank"
        end
      end
      row :latitude
      row :longitude
      row :phone
      row "Photo" do |lodging|
        if lodging.photo.attached?
          image_tag url_for(lodging.photo), style: 'max-width: 300px'
        else
          "No photo attached"
        end
      end
      row :created_at
      row :updated_at
    end
  end

  # Permit all parameters
  permit_params :name, :location_id, :address, :formatted_address, :lodging_type, 
                :description, :amenities, :rating, :price_range, :website, 
                :latitude, :longitude, :phone, :photo
end
