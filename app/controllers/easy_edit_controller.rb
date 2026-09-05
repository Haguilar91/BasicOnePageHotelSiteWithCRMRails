# Powers "Easy Edit": a lightweight WYSIWYG-style overlay on the public
# site. When session[:easy_edit] is on (toggled via #enable/#disable, linked
# from the Avo profile menu), pencil icons appear over editable cards/text
# on the homepage — clicking one opens a modal loaded from #edit, and saving
# posts to #update via AJAX. Scoped deliberately to text + photo fields only
# (matching the request this was built for); ordering, booking config,
# dates, and toggles stay Avo-only.
#
# Resources marked `deletable: true` also get a red trash button in the
# modal, which removes the record outright (see #destroy). PageContent is
# deliberately *not* deletable — its rows are keyed site copy that the
# templates look up by name, so deleting one silently drops a heading or a
# paragraph off the page with no way to get it back from this UI.
class EasyEditController < ApplicationController
  MODELS = {
    "room" => {
      model: Room,
      deletable: true,
      label: "Habitación",
      record_label: ->(r) { Mobility.with_locale(:es) { r.name }.presence || "Room ##{r.id}" },
      fields: {
        name: { type: :text, label: "Nombre" },
        badge: { type: :text, label: "Etiqueta" },
        price: { type: :text, label: "Precio" },
        booking_platform: {
          type: :select, label: "Plataforma de reserva",
          options: Room::BOOKING_PLATFORMS.transform_values { |meta| meta[:label] }.invert
        },
        booking_url: { type: :text, label: "Enlace de reserva" },
        button_name: { type: :text, label: "Texto del botón (opcional, usa el de la plataforma si se deja vacío)" },
        description: { type: :textarea, label: "Descripción" },
        features: { type: :textarea, label: "Características (una por línea)" },
        photos: { type: :files, label: "Fotos" }
      }
    },
    "offer" => {
      model: Offer,
      deletable: true,
      label: "Oferta",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Offer ##{r.id}" },
      fields: {
        title: { type: :text, label: "Título" },
        badge: { type: :text, label: "Etiqueta" },
        description: { type: :textarea, label: "Descripción" },
        booking_url: { type: :text, label: "Enlace de reserva (opcional, usa la sección de reservar si se deja vacío)" },
        ticker_description: { type: :textarea, label: "Texto para el ticker" },
        photo: { type: :file, label: "Imagen" }
      }
    },
    "page_content" => {
      model: PageContent,
      label: "Texto del sitio",
      finder: ->(id) { PageContent.find_by!(key: id) },
      record_label: ->(r) { r.title.presence || r.key },
      fields: {
        content: { type: :textarea, label: "Contenido" }
      }
    },
    "experience" => {
      model: Experience,
      deletable: true,
      label: "Experiencia",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Experience ##{r.id}" },
      fields: {
        title: { type: :text, label: "Título" },
        description: { type: :textarea, label: "Descripción" },
        icon_image: { type: :file, label: "Imagen del ícono" }
      }
    },
    "feature" => {
      model: Feature,
      deletable: true,
      label: "Característica",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Feature ##{r.id}" },
      fields: {
        title: { type: :text, label: "Título" },
        description: { type: :textarea, label: "Descripción" }
      }
    },
    "phone_number" => {
      model: PhoneNumber,
      deletable: true,
      label: "Teléfono",
      record_label: ->(r) { Mobility.with_locale(:es) { r.label }.presence || r.number },
      fields: {
        label: { type: :text, label: "Nombre de la línea (ej. Recepción)" },
        number: { type: :text, label: "Número" },
        whatsapp_active: { type: :boolean, label: "Línea de WhatsApp (solo una)" },
        call_active: { type: :boolean, label: "Línea de llamadas (solo una)" },
        visible: { type: :boolean, label: "Mostrar en la página" },
        position: { type: :number, label: "Orden" }
      }
    },
    "local_activity" => {
      model: LocalActivity,
      deletable: true,
      label: "Actividad",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Activity ##{r.id}" },
      fields: {
        title: { type: :text, label: "Título" },
        description: { type: :textarea, label: "Descripción" },
        google_maps_url: { type: :text, label: "Enlace de Google Maps" },
        photo: { type: :file, label: "Foto" }
      }
    }
  }.freeze

  before_action :require_admin!
  before_action :load_resource_config, only: [ :edit, :update, :destroy ]
  before_action :load_record, only: [ :edit, :update, :destroy ]

  layout false

  # Always lands on the public site, never `redirect_back` — this is always
  # clicked from Avo (a completely different page), so the referer is
  # "/avo" itself, and redirect_back would just bounce the admin right back
  # to the page they clicked it from instead of actually taking them to the
  # site to edit.
  def enable
    session[:easy_edit] = true
    redirect_to root_path
  end

  def disable
    session[:easy_edit] = false
    redirect_back fallback_location: root_path
  end

  def edit
    Mobility.with_locale(:es) do
      # Pass the raw :id straight through rather than @record.id — for most
      # resources they're the same thing, but "page_content" is looked up
      # by its `key` string (see MODELS[...][:finder] above), and the form
      # must re-submit that same identifier, not the record's numeric
      # database id, or the update request 404s.
      render partial: "easy_edit/form",
        locals: { resource: params[:resource], id: params[:id], config: @config, record: @record }
    end
  end

  # Always writes to the :es locale regardless of which language the admin
  # is currently browsing the site in — Easy Edit is the primary content
  # editor (same role as Avo), so it edits the Spanish source; English stays
  # the Translations panel's job, keeping that review step intact.
  def update
    Mobility.with_locale(:es) do
      @config[:fields].each do |field, field_config|
        next unless params[:record]&.key?(field.to_s)

        case field_config[:type]
        when :files
          files = Array(params[:record][field.to_s]).reject(&:blank?)
          @record.public_send(field).attach(files) if files.any?
        when :boolean
          # The form pairs every checkbox with a hidden "0", so an unchecked
          # box still submits and can actually turn a flag off.
          @record.public_send("#{field}=", ActiveModel::Type::Boolean.new.cast(params[:record][field.to_s]))
        else
          @record.public_send("#{field}=", params[:record][field.to_s])
        end
      end

      if @record.save
        render json: { ok: true }
      else
        render json: { ok: false, errors: @record.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  # Deleting is opt-in per resource (`deletable: true`) — see the note at the
  # top of this file for why PageContent is excluded. The modal asks for
  # confirmation before this is ever called; the guard here is what actually
  # enforces it, since the request can be replayed by hand.
  def destroy
    unless @config[:deletable]
      return render json: { ok: false, errors: [ "Este elemento no se puede eliminar desde Easy Edit." ] },
        status: :forbidden
    end

    if @record.destroy
      render json: { ok: true }
    else
      render json: { ok: false, errors: @record.errors.full_messages.presence || [ "No se pudo eliminar." ] },
        status: :unprocessable_entity
    end
  end

  private

  # #enable/#disable are plain link clicks (not AJAX), so they get a normal
  # redirect on failure; #edit/#update are only ever called by the modal's
  # fetch() calls, so JSON is what the JS actually expects back.
  def require_admin!
    return if current_user&.admin?

    if action_name.in?(%w[enable disable])
      redirect_to(current_user ? root_path : new_user_session_path, alert: "No tienes permiso para usar Easy Edit.")
    else
      render json: { ok: false, error: "not authorized" }, status: :forbidden
    end
  end

  def load_resource_config
    @config = MODELS.fetch(params[:resource]) { raise ActionController::RoutingError, "Unknown Easy Edit resource" }
  end

  def load_record
    finder = @config[:finder] || ->(id) { @config[:model].find(id) }
    @record = finder.call(params[:id])
  end
end
