class Avo::Resources::PageContent < Avo::BaseResource
  self.title = :title
  self.icon = "fas fa-book-open"
  self.includes = [:logo_attachment, :favicon_attachment, :app_icon_attachment, :images_attachments]

  def self.navigation_label
    "Contenido"
  end
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
  end
end


