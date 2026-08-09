class CreateLocalActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :local_activities do |t|
      t.string :title, null: false
      t.string :category, null: false
      t.text :description, null: false
      t.string :google_maps_url, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :local_activities, :category
    add_index :local_activities, :position
  end
end
