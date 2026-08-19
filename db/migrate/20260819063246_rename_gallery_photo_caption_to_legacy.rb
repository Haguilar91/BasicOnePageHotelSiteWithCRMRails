class RenameGalleryPhotoCaptionToLegacy < ActiveRecord::Migration[8.1]
  def change
    rename_column :gallery_photos, :caption, :caption_legacy
  end
end
