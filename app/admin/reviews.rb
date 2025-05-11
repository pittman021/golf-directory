ActiveAdmin.register Review do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :user_id, :course_id, :rating, :played_on, :course_condition, :comment
  #
  # or
  #
  # permit_params do
  #   permitted = [:user_id, :course_id, :rating, :played_on, :course_condition, :comment]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  # Index page configuration
  index do
    selectable_column
    id_column
    column :course
    column :user
    column :rating
    column :comment do |review|
      truncate(review.comment, length: 100) if review.comment.present?
    end
    column :status
    column :created_at
    actions
  end

  # Filters
  filter :course, collection: proc { Course.all.map { |c| [c.name, c.id] } }
  filter :user
  filter :rating
  filter :status, as: :select
  filter :created_at

  # Form customization
  form do |f|
    f.inputs "Review Details" do
      f.input :course, collection: Course.all.map { |c| [c.name, c.id] }
      f.input :user
      f.input :rating, as: :select, collection: (1..5)
      f.input :comment
      f.input :status, as: :select, collection: Review.statuses.map { |k, v| [k.humanize, k] }
    end
    f.actions
  end

  # Show page
  show do
    attributes_table do
      row :id
      row :course
      row :user
      row :rating do |review|
        "#{review.rating} stars"
      end
      row :comment
      row :status
      row :created_at
      row :updated_at
    end
  end

  # Add action to approve reviews
  action_item :approve, only: :show, if: proc { resource.status != "approved" } do
    link_to "Approve Review", approve_admin_review_path(resource), method: :put
  end

  # Add action to reject reviews
  action_item :reject, only: :show, if: proc { resource.status != "rejected" } do
    link_to "Reject Review", reject_admin_review_path(resource), method: :put
  end

  # Controller actions for approving/rejecting
  member_action :approve, method: :put do
    resource.approved!
    redirect_to admin_review_path(resource), notice: "Review approved!"
  end

  member_action :reject, method: :put do
    resource.rejected!
    redirect_to admin_review_path(resource), notice: "Review rejected!"
  end

  # Batch actions
  batch_action :approve do |ids|
    batch_action_collection.find(ids).each do |review|
      review.approved!
    end
    redirect_to collection_path, notice: "Reviews approved!"
  end

  batch_action :reject do |ids|
    batch_action_collection.find(ids).each do |review|
      review.rejected!
    end
    redirect_to collection_path, notice: "Reviews rejected!"
  end

  # Permit all parameters
  permit_params :course_id, :user_id, :rating, :comment, :status
end
