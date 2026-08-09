class Avo::Resources::Room < Avo::BaseResource
  self.title = :name
  self.icon = "fas fa-bed"
  self.includes = [:photo_attachment]

  def self.navigation_label
    "Habitaciones"
  end
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
    field :photo, as: :file, is_image: true, help: "Fotografía principal de la habitación"
    field :position, as: :number, help: "Orden de aparición en la página principal (1, 2, 3...)"
  end
end
