class CreateLodgings < ActiveRecord::Migration[7.0]
  def change
    create_table :lodgings do |t|
      # Google Places Data
      t.string :google_place_id, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :types, array: true, default: []
      t.decimal :rating
      t.decimal :latitude
      t.decimal :longitude
      t.string :formatted_address
      t.string :formatted_phone_number
      t.string :website
      
      # Research Information
      t.text :research_notes
      t.string :research_status, default: 'pending' # pending, in_progress, completed
      t.date :research_last_attempted
      t.integer :research_attempts, default: 0
      
      # Relationships
      t.references :location, null: false, foreign_key: true
      
      # Display Control
      t.boolean :is_featured, default: false
      t.integer :display_order
      
      t.timestamps
    end
  end
end 