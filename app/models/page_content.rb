class PageContent < ApplicationRecord
  extend Mobility
  # `key` (lookup id) and `title` (admin-panel-only label) stay plain columns.
  translates :content, backend: :key_value, type: :text

  has_many_attached :images

  # Specific attachments for brand assets
  has_one_attached :logo
  has_one_attached :favicon
  has_one_attached :app_icon
end
