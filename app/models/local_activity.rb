class LocalActivity < ApplicationRecord
  has_one_attached :photo

  CATEGORIES = [
    'Restaurantes',
    'Puntos de Interés',
    'Tours'
  ].freeze

  validates :title, :category, :description, :google_maps_url, presence: true
  validates :category, inclusion: { in: CATEGORIES }
end
