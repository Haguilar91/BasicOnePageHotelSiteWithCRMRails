class CreateHeroImages < ActiveRecord::Migration[8.1]
  def change
    create_table :hero_images do |t|
      t.string :image

      t.timestamps
    end
  end
end
