class CreateGalleryPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :gallery_photos do |t|
      t.string :caption
      t.integer :position, default: 0, null: false

      t.timestamps
    end
  end
end
