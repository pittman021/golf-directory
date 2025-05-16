class ChangeSummaryToJsonbOnLocations < ActiveRecord::Migration[7.2]
  def change
    change_column :locations, :summary, :jsonb, using: 'summary::jsonb'
  end
end
