# Replaces the single `contact_phone` PageContent value with a real list, so
# the hotel can run separate lines for WhatsApp and for calls and still show
# the rest (reception, restaurant, events...) on the contact section.
#
# `label` isn't a column — it goes through Mobility's KeyValue store like
# every other translated field in this app (see PhoneNumber).
class CreatePhoneNumbers < ActiveRecord::Migration[8.1]
  def change
    create_table :phone_numbers do |t|
      t.string :number, null: false
      # At most one row may carry each flag — enforced in the model rather
      # than by a partial unique index, so flipping the flag onto a different
      # row is a single save instead of a two-step dance.
      t.boolean :whatsapp_active, default: false, null: false
      t.boolean :call_active, default: false, null: false
      # Whether the number is listed in the public contact section. The
      # WhatsApp/call lines are used by their buttons regardless of this.
      t.boolean :visible, default: true, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :phone_numbers, :position
    add_index :phone_numbers, :whatsapp_active
    add_index :phone_numbers, :call_active
  end
end
