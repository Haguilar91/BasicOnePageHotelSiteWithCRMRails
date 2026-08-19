class GalleryPhoto < ApplicationRecord
  extend Mobility
  translates :caption, backend: :key_value, type: :string

  has_one_attached :photo
end
