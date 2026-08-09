class Avo::Resources::LocalActivity < Avo::BaseResource
  self.title = :title
  self.icon = "heroicons/outline/location-marker"
  self.includes = [:photo_attachment]

  def fields
    field :id, as: :id, readonly: true

    field :title, as: :text, required: true, help: 'Nombre del lugar o experiencia.'
    field :category, as: :select, options: LocalActivity::CATEGORIES, required: true, help: 'Categoría del elemento.'
    field :description, as: :textarea, show_on: :all, help: 'Descripción breve del lugar o tour.'
    field :google_maps_url, as: :text, required: true, help: 'Enlace directo a Google Maps.'
    field :photo, as: :file, is_image: true, help: 'Imagen representativa del punto de interés.'
    field :position, as: :number, help: 'Orden de aparición en la página principal.'
  end
end
