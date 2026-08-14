class Avo::Resources::Offer < Avo::BaseResource
  self.title = :display_title
  self.icon = "heroicons/outline/tag"
  self.includes = [:room, :photo_attachment]
  self.search = {
    query: -> { query.ransack(title_cont: q, description_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id, readonly: true

    field "Tipo de oferta", as: :heading

    field :kind,
      as: :select,
      name: "Tipo",
      options: Offer::KINDS.invert,
      default: Offer::PACKAGE,
      include_blank: false,
      help: "«Oferta de Habitación» aplica un descuento a una habitación existente. «Paquete» es una promoción independiente con su propio precio."

    field "Datos generales", as: :heading

    # Avo infers "required" from the presence validators alone, which ignores
    # their `if:`/`unless:` conditions — so these are set explicitly to match
    # the kind actually saved on the record.
    field :title, as: :text, name: "Título",
      required: -> { !record.room_offer? },
      format_index_using: -> { record.display_title },
      help: "Obligatorio en paquetes. En ofertas de habitación puedes dejarlo vacío para usar el nombre de la habitación."
    field :description, as: :textarea, name: "Descripción", hide_on: :index,
      help: "Descripción mostrada en la tarjeta de la oferta."

    field "Oferta de habitación", as: :heading

    field :room, as: :belongs_to, name: "Habitación", hide_on: :index,
      required: -> { record.room_offer? },
      help: "Habitación a la que aplica el descuento."
    field :discount_percent, as: :number, name: "Descuento (%)", hide_on: :index,
      required: -> { record.room_offer? },
      help: "Porcentaje de descuento, ej. 15. El precio rebajado se calcula automáticamente a partir del precio de la habitación."
    field :price_preview, as: :text, name: "Precio resultante", only_on: :show, as_html: true,
      format_using: -> {
        next "—" unless record.room_offer?
        original = record.original_price
        discounted = record.discounted_price
        next "No se pudo calcular a partir de «#{original}»" if discounted.blank?

        "<span class='line-through opacity-60'>#{ERB::Util.html_escape(original)}</span> <strong>#{ERB::Util.html_escape(discounted)}</strong>".html_safe
      }

    field "Paquete", as: :heading

    field :price, as: :number, name: "Precio", step: 0.01, hide_on: :index,
      help: "Precio del paquete. Solo se usa en paquetes; las ofertas de habitación calculan su precio con el descuento."
    field :badge, as: :text, name: "Etiqueta", hide_on: :index,
      help: "Etiqueta destacada (ej: 20% DESCUENTO, ÚLTIMOS DÍAS). En ofertas de habitación se genera automáticamente si la dejas vacía."
    field :booking_url, as: :text, name: "Enlace de reserva", hide_on: :index,
      help: "Enlace para reservar esta oferta. Si se deja vacío, el botón lleva a la sección de reservar."

    field :photo, as: :file, is_image: true, name: "Imagen", hide_on: :index,
      help: "Imagen de la oferta. En ofertas de habitación, si la dejas vacía se usa la foto de la habitación."

    field "Ticker de anuncios", as: :heading

    field :show_on_ticker, as: :boolean, name: "Mostrar en el ticker", hide_on: :index,
      help: "Muestra esta oferta en la cinta de anuncios que corre en la parte superior del sitio."
    field :ticker_description, as: :textarea, name: "Texto para el ticker", hide_on: :index,
      help: "Texto breve para la cinta de anuncios. Si lo dejas vacío se usa la descripción de la oferta."

    field "Publicación", as: :heading

    field :active, as: :boolean, name: "Activa", hide_on: :index, help: "Mostrar esta oferta en el sitio web."
    field :valid_from, as: :date, name: "Válida desde", hide_on: :index,
      help: "Fecha en la que empieza a mostrarse (opcional). Déjala vacía para publicarla de inmediato."
    field :valid_until, as: :date, name: "Válida hasta", hide_on: :index,
      help: "Fecha límite de la oferta (opcional). Pasada esta fecha deja de mostrarse en el sitio."
    field :status, as: :text, name: "Estado", only_on: [:index, :show], as_html: true,
      format_using: -> {
        label, color = if !record.active? then ["Inactiva", "#6b7280"]
        elsif record.scheduled? then ["Programada · inicia #{record.valid_from.strftime("%d/%m/%Y")}", "#b45309"]
        elsif record.expired? then ["Expirada", "#b91c1c"]
        else ["Publicada", "#047857"]
        end

        "<span style='color:#{color};font-weight:600'>#{ERB::Util.html_escape(label)}</span>".html_safe
      }
    field :position, as: :number, name: "Posición",
      help: "Orden de aparición en la página principal (1, 2, 3...)"
  end
end
