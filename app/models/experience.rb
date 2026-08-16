class Experience < ApplicationRecord
  extend Mobility
  translates :title, backend: :key_value, type: :string
  translates :description, backend: :key_value, type: :text

  has_one_attached :icon_image
end
