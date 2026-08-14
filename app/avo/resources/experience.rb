class Avo::Resources::Experience < Avo::BaseResource
  self.title = :title
  self.icon = "heroicons/outline/table-cells"
  self.includes = [:icon_image_attachment]
  self.search = {
    query: -> { query.ransack(title_cont: q, description_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id, readonly: true
    field :title, as: :text, required: true, help: "Título del servicio o experiencia (ej: Restaurante, Piscina, Gimnasio, Spa)"
    field :description, as: :textarea, show_on: :all, help: "Descripción breve del servicio"
    field :icon, as: :select, grouped_options: FontAwesomeIcons.grouped_select_options, include_blank: "Selecciona un icono...",
      show_on: :all, help: "Selecciona el icono representativo para la experiencia (Font Awesome 6, estilo solid)"
    field :icon_image, as: :file, is_image: true, help: "Opcional: Subir imagen de icono personalizada (reemplaza el icono seleccionado)"
    field :position, as: :number, help: "Orden de aparición (1, 2, 3...)"
  end
end
