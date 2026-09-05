class Avo::Resources::Theme < Avo::BaseResource
  self.title = :name
  self.icon = "heroicons/outline/color-swatch"
  self.includes = []
  self.search = {
    query: -> { query.ransack(name_cont: q, slug_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id, readonly: true

    field "Tema", as: :heading

    field :name, as: :text, help: "Nombre para identificar el tema, ej. 'Dorado Colonial'"
    field :slug, as: :text, readonly: -> { record.persisted? }, help: "Identificador único, se genera automáticamente a partir del nombre."
    field :active, as: :boolean, name: "Tema activo", help: "Solo un tema puede estar activo a la vez. Al activar este, se desactivan los demás y el sitio web usará estos colores de inmediato."
    field :position, as: :number, help: "Orden en el que aparece este tema en la lista."

    field "Colores", as: :heading

    swatch_field :bg_primary, name: "Fondo principal", help: "Fondo más oscuro: navegación, pie de página, secciones base."
    swatch_field :bg_secondary, name: "Fondo secundario", help: "Fondo de tarjetas y secciones alternas."
    swatch_field :bg_tertiary, name: "Fondo terciario", help: "Fondo de elementos como iconos y botones secundarios."
    swatch_field :accent, name: "Acento", help: "Color principal de marca: botones, íconos y detalles destacados."
    swatch_field :accent_soft, name: "Acento suave", help: "Tono claro del acento, usado en degradados y brillos."
    swatch_field :text_muted, name: "Texto atenuado", help: "Color de textos secundarios sobre fondos oscuros."
  end

  private

  def swatch_field(attribute, name:, help:)
    field attribute,
      as: :text,
      name: name,
      help: help,
      as_html: true,
      format_using: -> {
        next value if view.in?([ :edit, :new ])
        hex = value.to_s
        next "" if hex.blank?

        content_tag(:span, class: "inline-flex items-center gap-2") do
          content_tag(:span, "", style: "display:inline-block;width:1rem;height:1rem;border-radius:9999px;border:1px solid rgba(0,0,0,0.15);background-color:#{hex};") +
            content_tag(:span, hex, class: "font-mono text-sm")
        end
      }
  end
end
