class Avo::Resources::Room < Avo::BaseResource
  self.title = :name
  self.icon = "heroicons/outline/key"
  self.includes = [photos_attachments: :blob]
  self.search = {
    query: -> { query.ransack(name_cont: q, description_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id, readonly: true
    field :name, as: :text, required: true, help: "Nombre o categoría de la habitación (ej: Habitación Standard, Habitación Deluxe)"
    field :price, as: :text, help: "Precio por noche (ej: Desde $150)"
    field :badge, as: :text, help: "Etiqueta opcional destacada (ej: POPULAR, OFERTA, VIP)"
    field :description, as: :textarea, show_on: :all, help: "Descripción detallada de la habitación"
    field :features, as: :textarea, show_on: :all, help: "Características incluidas (escribe una por línea, ej: Cama King Size, Jacuzzi, Balcón)"
    field :booking_url, as: :text, help: "Enlace directo para reservar en Booking.com, Airbnb, WhatsApp o motor propio"
    field :booking_platform,
      as: :select,
      options: Room::BOOKING_PLATFORMS.transform_values { |meta| meta[:label] }.invert,
      default: "custom",
      help: "Elige una plataforma para mostrar su ícono junto al botón de reserva."
    field :button_name, as: :text, placeholder: "Reservar", help: "Texto del botón de reserva. Déjalo en blanco para usar el texto predeterminado de la plataforma elegida (ej. 'Reservar en Airbnb')."
    field :photos, as: :files, is_image: true,
      help: "Fotografías de la habitación (puedes subir varias; se mostrarán como galería en la tarjeta de la habitación). Puedes elegir archivos de varias carpetas en distintos pasos antes de guardar.",
      components: { edit_component: "RoomPhotosUploadEditComponent" }
    field :position, as: :number, help: "Orden de aparición en la página principal (1, 2, 3...)"
  end
end
