class Avo::Resources::GalleryPhoto < Avo::BaseResource
  self.title = :id
  self.icon = "heroicons/outline/photograph"
  self.includes = [ :photo_attachment ]

  def fields
    field :id, as: :id, readonly: true
    field :photo, as: :file, is_image: true, required: true,
      help: "Foto general del hotel (lobby, terraza, fachada, pasillos, jardín, etc. — NO fotos de habitaciones, esas van en Habitaciones)."
    field :caption, as: :text, help: "Descripción breve opcional (ej: Terraza, Lobby, Fachada principal)."
    field :position, as: :number, help: "Orden de aparición en la galería (1, 2, 3...)."
  end
end
