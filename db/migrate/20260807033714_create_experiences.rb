class CreateExperiences < ActiveRecord::Migration[8.1]
  def change
    create_table :experiences do |t|
      t.string :title
      t.text :description
      t.string :icon
      t.integer :position

      t.timestamps
    end
  end
end
