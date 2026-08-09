# app/avo/resources/hero_image.rb
class Avo::Resources::HeroImage < Avo::BaseResource
  self.title = :id
  self.icon = "heroicons/outline/photo"
  # self.includes = []

  def fields
    field :id, as: :id
    field :image, as: :file
  end
end