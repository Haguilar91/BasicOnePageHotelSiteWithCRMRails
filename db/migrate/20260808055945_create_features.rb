class CreateFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :features do |t|
      t.string :title
      t.text :description
      t.string :icon
      t.integer :position

      t.timestamps
    end
  end
end
