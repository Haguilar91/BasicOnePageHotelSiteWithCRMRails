# app/avo/resources/feature.rb
class Avo::Resources::Feature < Avo::BaseResource
  self.title = :title

  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :position, as: :number

    # Dropdown con íconos recomendados para las Features
    field :icon, as: :select, options: {
      "Centro Histórico (landmark)" => "landmark",
      "Spa & Wellness (spa)" => "spa",
      "Gastronomía / Bar (glass-cheers)" => "glass-cheers",
      "Estacionamiento (car)" => "car",
      "Wi-Fi / Internet (wifi)" => "wifi",
      "Ambiente Familiar (users)" => "users",
      "Recepción 24/7 (concierge-bell)" => "concierge-bell",
      "Habitaciones / Confort (bed)" => "bed",
      "Restaurante (utensils)" => "utensils",
      "Piscina / Alberca (swimming-pool)" => "swimming-pool",
      "Seguridad (shield-alt)" => "shield-alt",
      "Estrella / General (star)" => "star"
    }, default: "landmark"
  end
end