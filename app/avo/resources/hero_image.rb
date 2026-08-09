# app/avo/resources/hero_image.rb
class Avo::Resources::HeroImage < Avo::BaseResource
  self.title = :id
  self.icon = "fas fa-image"

  def self.navigation_label
    "Hero Images"
  end

  # self.includes = []

  def fields
    field :id, as: :id
    field :image, as: :file
  end
end