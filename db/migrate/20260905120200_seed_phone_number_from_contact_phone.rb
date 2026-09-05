# Carries the single `contact_phone` PageContent value over into the new
# phone_numbers table, flagged for both roles, so an existing site keeps the
# exact number it had on the "Llamar ahora" and WhatsApp buttons without an
# admin having to re-enter it.
class SeedPhoneNumberFromContactPhone < ActiveRecord::Migration[8.1]
  def up
    return if PhoneNumber.exists?

    number = Mobility.with_locale(:es) { PageContent.find_by(key: "contact_phone")&.content }
    return if number.blank?

    phone = PhoneNumber.create!(
      number: number.strip,
      whatsapp_active: true,
      call_active: true,
      visible: true,
      position: 0
    )
    Mobility.with_locale(:es) { phone.update!(label: "Recepción") }
  end

  def down
    # No-op: the seeded row is ordinary editable data by now, and dropping it
    # would throw away whatever the admin has since changed it to.
  end
end
