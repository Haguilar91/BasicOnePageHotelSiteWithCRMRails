class Avo::Resources::Experience < Avo::BaseResource
  self.title = :title
  self.includes = [:icon_image_attachment]
  self.search = {
    query: -> { query.ransack(title_cont: q, description_cont: q).result(distinct: false) }
  }

  ICON_OPTIONS = {
    "Utensils (Restaurante)" => "utensils",
    "Swimmer (Piscina)" => "swimmer",
    "Dumbbell (Gimnasio)" => "dumbbell",
    "Car (Transporte)" => "car",
    "Spa (Spa & Wellness)" => "spa",
    "Glass-Cheers (Bar & Bebidas)" => "glass-cheers",
    "Coffee (Café & Desayuno)" => "coffee",
    "Wifi (Internet Wi-Fi)" => "wifi",
    "Concierge-Bell (Concierge 24/7)" => "concierge-bell",
    "Parking (Estacionamiento)" => "parking",
    "Key (Check-in & Llave)" => "key",
    "Landmark (Centro Histórico)" => "landmark",
    "Bed (Habitaciones)" => "bed",
    "Gem (Servicio VIP)" => "gem",
    "Star (Experiencia Destacada)" => "star",
    "Umbrella-Beach (Terraza / Solárium)" => "umbrella-beach",
    "Shield-Alt (Seguridad)" => "shield-alt"
  }.freeze

  def fields
    field :id, as: :id, readonly: true
    field :title, as: :text, required: true, help: "Título del servicio o experiencia (ej: Restaurante, Piscina, Gimnasio, Spa)"
    field :description, as: :textarea, show_on: :all, help: "Descripción breve del servicio"
    field :icon, as: :select, options: ICON_OPTIONS, include_blank: "Selecciona un icono...", as_html: true, format_using: -> {
      if value.present?
        label = ICON_OPTIONS.key(value) || value
        "<div class='flex items-center space-x-2'><i class='fas fa-#{value} text-amber-500 text-xl w-6 text-center'></i> <span>#{label}</span></div>".html_safe
      end
    }, show_on: :all, help: "Selecciona el icono representativo para la experiencia"
    field :icon_image, as: :file, is_image: true, help: "Opcional: Subir imagen de icono personalizada (reemplaza el icono seleccionado)"
    field :position, as: :number, help: "Orden de aparición (1, 2, 3...)"
  end
end
