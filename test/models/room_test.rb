require "test_helper"

class RoomTest < ActiveSupport::TestCase
  test "booking_platform must be one of the known platforms" do
    assert create_es(Room, name: "Suite", booking_platform: "airbnb").valid?
    assert_not Room.new(booking_platform: "expedia").valid?
  end

  test "booking_platform defaults to custom" do
    assert_equal "custom", Room.new.booking_platform
  end

  test "booking_button_label uses the platform default when no name is set" do
    room = create_es(Room, name: "Suite", booking_platform: "airbnb")
    I18n.with_locale(:es) { assert_equal "Reservar en Airbnb", room.booking_button_label }
  end

  test "booking_button_label prefers the admin's own button text" do
    room = create_es(Room, name: "Suite", booking_platform: "airbnb", button_name: "Ver disponibilidad")
    Mobility.with_locale(:es) { assert_equal "Ver disponibilidad", room.booking_button_label }
  end

  test "booking_button_label follows the current locale" do
    room = create_es(Room, name: "Suite", booking_platform: "booking")

    I18n.with_locale(:es) { assert_equal "Reservar en Booking.com", room.booking_button_label }
    I18n.with_locale(:en) { assert_equal "Book on Booking.com", room.booking_button_label }
  end

  test "an unrecognised platform falls back to custom rather than blowing up" do
    # Validation keeps this out of the database, but the record can still be
    # in memory (a half-filled Avo form), and the button must still render.
    room = Room.new(booking_platform: "expedia")
    I18n.with_locale(:es) do
      assert_equal "Reservar", room.booking_button_label
      assert_equal "fa-solid fa-calendar-check", room.booking_button_icon
    end
  end

  test "booking_button_icon comes from the platform" do
    room = create_es(Room, name: "Suite", booking_platform: "whatsapp")
    assert_equal "fa-brands fa-whatsapp", room.booking_button_icon
  end

  test "deleting a room takes its offers with it" do
    room = create_es(Room, name: "Suite")
    create_es(Offer, kind: Offer::ROOM, room:, discount_percent: 10)

    assert_difference("Offer.count", -1) { room.destroy }
  end

  test "translated fields are stored per locale" do
    room = create_es(Room, name: "Habitación Doble", description: "Con balcón")
    Mobility.with_locale(:en) { room.update!(name: "Double Room") }

    Mobility.with_locale(:es) { assert_equal "Habitación Doble", room.reload.name }
    Mobility.with_locale(:en) { assert_equal "Double Room", room.reload.name }
  end

  test "an untranslated field falls back to the Spanish source" do
    room = create_es(Room, name: "Habitación Doble")
    Mobility.with_locale(:en) { assert_equal "Habitación Doble", room.reload.name }
  end
end
