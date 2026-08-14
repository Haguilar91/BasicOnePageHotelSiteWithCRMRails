class AddButtonNameToRooms < ActiveRecord::Migration[8.1]
  def up
    # No DB default here on purpose: a blank button_name means "use the
    # selected platform's default label" (see Room#booking_button_label).
    add_column :rooms, :button_name, :string
    add_column :rooms, :booking_platform, :string, default: "custom", null: false

    # Preserve the previous behavior (which guessed the platform from the URL)
    # for any rooms that already have a booking_url set.
    execute "UPDATE rooms SET booking_platform = 'booking' WHERE booking_url LIKE '%booking%'"
    execute "UPDATE rooms SET booking_platform = 'airbnb' WHERE booking_url LIKE '%airbnb%'"
    execute "UPDATE rooms SET booking_platform = 'whatsapp' WHERE booking_url LIKE '%wa.me%' OR booking_url LIKE '%whatsapp%'"
  end

  def down
    remove_column :rooms, :button_name
    remove_column :rooms, :booking_platform
  end
end
