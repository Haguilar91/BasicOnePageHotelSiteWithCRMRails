class Avo::Resources::PageContent < Avo::BaseResource
  self.title = :title
  self.icon = "heroicons/outline/book-open"
  self.includes = [:logo_attachment, :favicon_attachment, :app_icon_attachment, :images_attachments]
  self.search = {
    query: -> { query.ransack(title_cont: q, key_cont: q, content_cont: q).result(distinct: false) }
  }

  def fields
    field :id, as: :id, readonly: true

    field "Contenido Editable", as: :heading

    field :key, as: :text, readonly: -> { record.present? }, help: 'Identificador único (ej: home_hero_title, contact_email). No se puede cambiar después de crear.'
    field :title, as: :text, help: 'Título descriptivo para el panel de administración'
    field :content, as: :textarea, show_on: :all, help: 'Contenido principal o valor del texto para esta clave.'

    field "Archivos e Imágenes Adjuntas", as: :heading

    field :logo, as: :file, is_image: true, help: "Logo principal del sitio (para registro 'global')"
    field :favicon, as: :file, is_image: true, help: "Favicon del sitio (para registro 'global')"
    field :app_icon, as: :file, is_image: true, help: "Icono de aplicación PWA (para registro 'global')"
    field :images, as: :files, is_image: true, help: "Imágenes o fotografías adjuntas"

    field "Botones de Contacto (CTA)", as: :heading

    field :show_cta_call, as: :boolean, name: "Mostrar botón «Llamar Ahora»",
      help: "Solo aplica al registro 'global'. Desactívalo para ocultar el botón de llamada en la sección final de reserva y como opción de canal en el formulario de reserva, sin perder el número guardado."
    field :show_cta_whatsapp, as: :boolean, name: "Mostrar botón «Enviar WhatsApp»",
      help: "Solo aplica al registro 'global'. Controla si WhatsApp aparece como botón en la sección final de reserva y como opción de canal en el formulario de reserva — es decir, si el formulario puede enviarse por WhatsApp."
    field :show_cta_email, as: :boolean, name: "Mostrar botón «Enviar Email»",
      help: "Solo aplica al registro 'global'. Controla si el correo aparece como botón en la sección final de reserva y como opción de canal en el formulario de reserva — es decir, si el formulario puede enviarse por correo. Activa ambos (WhatsApp y Email) para que el huésped pueda elegir cualquiera de los dos."
  end
end


