class LocalActivity < ApplicationRecord
  extend Mobility
  translates :title, backend: :key_value, type: :string
  translates :description, backend: :key_value, type: :text

  has_one_attached :photo

  # These stay the stable DB/lookup values (also used for the Avo select
  # field, DOM tab wiring via `.parameterize`, and icon selection) — only
  # the rendered label is translated, via CATEGORY_I18N_KEYS/category_label
  # below, so existing rows and the Spanish-only Avo admin form don't need
  # to change.
  CATEGORIES = [
    'Restaurantes',
    'Puntos de Interés',
    'Tours'
  ].freeze

  CATEGORY_I18N_KEYS = {
    'Restaurantes' => :restaurants,
    'Puntos de Interés' => :points_of_interest,
    'Tours' => :tours
  }.freeze

  validates :title, :category, :description, :google_maps_url, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  def self.category_label(category)
    I18n.t("models.local_activity.categories.#{CATEGORY_I18N_KEYS.fetch(category)}")
  end
end
