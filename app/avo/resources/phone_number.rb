class Avo::Resources::PhoneNumber < Avo::BaseResource
  self.title = :number
  self.icon = "heroicons/outline/phone"

  def fields
    field :id, as: :id, readonly: true

    field :label, as: :text, help: "Nombre de la línea (ej: Recepción, Restaurante, Eventos)."
    field :number, as: :text, required: true, help: "Número con lada, ej: +52 442 212 3456."
    field :whatsapp_active, as: :boolean,
      name: "Línea de WhatsApp",
      help: "Número al que abren los botones de WhatsApp. Solo uno puede estar activo — al marcarlo aquí se desmarca en los demás."
    field :call_active, as: :boolean,
      name: "Línea de llamadas",
      help: "Número que marca el botón \"Llamar ahora\". Solo uno puede estar activo — al marcarlo aquí se desmarca en los demás."
    field :visible, as: :boolean,
      name: "Mostrar en la página",
      help: "Si se lista en la sección de contacto del sitio."
    field :position, as: :number, help: "Orden de aparición en la sección de contacto."
  end
end
