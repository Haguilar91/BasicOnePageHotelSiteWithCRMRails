class TranslationsController < ApplicationController
  layout "translations"

  # Which models/fields show up in the panel, plus how to label each row
  # (the Spanish value of whatever field identifies the record) and which
  # field widget to render. `multiline: true` (Room#features) means the
  # field is a newline-delimited list — translated one line at a time
  # rather than as a single blob, since MyMemory tends to collapse embedded
  # newlines into a paragraph.
  MODELS = {
    Room => {
      label: "Habitaciones",
      record_label: ->(r) { Mobility.with_locale(:es) { r.name }.presence || "Room ##{r.id}" },
      fields: {
        name: { type: :text },
        badge: { type: :text },
        button_name: { type: :text },
        price: { type: :text },
        description: { type: :textarea },
        features: { type: :textarea, multiline: true }
      }
    },
    PageContent => {
      label: "Contenidos de página",
      record_label: ->(r) { r.key },
      fields: { content: { type: :textarea } }
    },
    Experience => {
      label: "Experiencias",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Experience ##{r.id}" },
      fields: { title: { type: :text }, description: { type: :textarea } }
    },
    Feature => {
      label: "Características",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Feature ##{r.id}" },
      fields: { title: { type: :text }, description: { type: :textarea } }
    },
    LocalActivity => {
      label: "Qué hacer",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Activity ##{r.id}" },
      fields: { title: { type: :text }, description: { type: :textarea } }
    },
    Offer => {
      label: "Ofertas",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Offer ##{r.id}" },
      fields: {
        title: { type: :text },
        badge: { type: :text },
        description: { type: :textarea },
        ticker_description: { type: :textarea }
      }
    },
    Announcement => {
      label: "Anuncios",
      record_label: ->(r) { Mobility.with_locale(:es) { r.title }.presence || "Announcement ##{r.id}" },
      fields: { title: { type: :textarea }, description: { type: :textarea } }
    }
  }.freeze

  before_action :require_admin!

  def index
    @sections = MODELS.map do |model, config|
      records = model.order(:id).map do |record|
        {
          id: record.id,
          label: config[:record_label].call(record),
          fields: config[:fields].map do |field, field_config|
            {
              name: field,
              type: field_config[:type],
              multiline: field_config[:multiline] || false,
              es: Mobility.with_locale(:es) { record.public_send(field) },
              en: Mobility.with_locale(:en) { record.public_send(field, fallback: false) }
            }
          end
        }
      end

      { param_key: model.model_name.param_key, label: config[:label], records: records }
    end
  end

  def update
    MODELS.each do |model, config|
      submitted = params.dig(:translations, model.model_name.param_key)
      next if submitted.blank?

      submitted.each do |id, field_values|
        record = model.find_by(id: id)
        next unless record

        Mobility.with_locale(:en) do
          config[:fields].each_key do |field|
            next unless field_values.key?(field.to_s)

            record.public_send("#{field}=", field_values[field.to_s])
          end
          record.save!(validate: false)
        end
      end
    end

    redirect_to translations_path, notice: t("translations_panel.saved")
  end

  # AJAX endpoint for the "Translate" button — returns translated text only,
  # never persists. The admin reviews/edits the result before a normal Save,
  # so machine translation stays advisory rather than silently publishing
  # unreviewed copy.
  def translate
    text = params[:text].to_s
    multiline = ActiveModel::Type::Boolean.new.cast(params[:multiline])
    result = multiline ? translate_multiline(text) : MachineTranslator.translate(text, from: "es", to: "en")

    if result.ok?
      render json: { translated: result.text }
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  private

  def translate_multiline(text)
    results = text.split("\n").map { |line| MachineTranslator.translate(line, from: "es", to: "en") }
    failed = results.find { |r| !r.ok? }
    return failed if failed

    MachineTranslator::Result.new(text: results.map(&:text).join("\n"), ok: true, error: nil)
  end

  def require_admin!
    return if current_user&.admin?

    redirect_to(current_user ? root_path : new_user_session_path, alert: t("translations_panel.not_authorized"))
  end
end
