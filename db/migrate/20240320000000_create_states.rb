class CreateStates < ActiveRecord::Migration[7.1]
  def change
    create_table :states do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :image_url
      t.string :best_months, array: true, default: []
      t.integer :featured_course_ids, array: true, default: []
      t.integer :featured_location_ids, array: true, default: []
      t.jsonb :summary, default: {}
      t.string :meta_title
      t.string :meta_description

      t.timestamps
    end

    add_index :states, :slug, unique: true
    add_index :states, :name, unique: true
  end
end 