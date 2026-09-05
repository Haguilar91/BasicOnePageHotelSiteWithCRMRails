# app/avo/resources/feature.rb
class Avo::Resources::Feature < Avo::BaseResource
  self.title = :title
  self.icon = "heroicons/outline/star"
  def fields
    field :id, as: :id
    field :title, as: :text
    field :description, as: :textarea
    field :position, as: :number

    # Dropdown con todos los íconos de Font Awesome 6 (solid); los recomendados
    # para hotel/turismo aparecen primero en su propio grupo.
    field :icon, as: :select, grouped_options: FontAwesomeIcons.grouped_select_options, default: "landmark",
      help: "Ícono mostrado en esta característica."
  end
end
