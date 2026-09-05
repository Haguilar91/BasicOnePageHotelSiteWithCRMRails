require "test_helper"

class OfferTest < ActiveSupport::TestCase
  # --- validations -------------------------------------------------------

  test "a package offer needs a title but no room" do
    assert create_es(Offer, kind: Offer::PACKAGE, title: "Fin de semana romántico").valid?
    assert_not Offer.new(kind: Offer::PACKAGE).valid?
  end

  test "a room offer needs a room and a discount instead of a title" do
    room = create_es(Room, name: "Suite Colonial")

    assert Offer.new(kind: Offer::ROOM, room:, discount_percent: 15).valid?
    assert_not Offer.new(kind: Offer::ROOM, discount_percent: 15).valid?, "room is required"
    assert_not Offer.new(kind: Offer::ROOM, room:).valid?, "discount_percent is required"
  end

  test "discount_percent must be a whole percentage between 1 and 99" do
    room = create_es(Room, name: "Suite Colonial")

    [ 0, 100, 150, -5 ].each do |percent|
      offer = Offer.new(kind: Offer::ROOM, room:, discount_percent: percent)
      assert_not offer.valid?, "#{percent} should be rejected"
      assert_includes offer.errors.attribute_names, :discount_percent
    end
  end

  test "kind must be one of the known kinds" do
    assert_not Offer.new(kind: "bogus", title: "x").valid?
  end

  test "valid_until cannot fall before valid_from" do
    offer = Offer.new(kind: Offer::PACKAGE, title: "x",
                      valid_from: Date.new(2026, 9, 10), valid_until: Date.new(2026, 9, 1))
    assert_not offer.valid?
    assert_includes offer.errors.attribute_names, :valid_until

    offer.valid_until = offer.valid_from
    assert offer.valid?, "the same day on both ends is a valid one-day offer"
  end

  # --- discounted_price --------------------------------------------------
  #
  # The room price is free-form text an admin typed, so the discount has to
  # come back out in whatever shape it went in.

  test "discounted_price keeps the room's own price formatting" do
    {
      # 127.5 rounds up, and to no decimals because the admin typed none.
      "Desde $150"   => "Desde $128",
      # Two decimals in, two decimals out.
      "$700.00 MXN"  => "$595.00 MXN",
      # The thousands separator survives the round trip.
      "$1,200"       => "$1,020"
    }.each do |room_price, expected|
      room = create_es(Room, name: "Suite #{room_price}", price: room_price)
      offer = Offer.new(kind: Offer::ROOM, room:, discount_percent: 15)
      assert_equal expected, offer.discounted_price, "for #{room_price.inspect}"
    end
  end

  test "discounted_price is nil when the room price has no number in it" do
    room = create_es(Room, name: "Suite", price: "Consultar")
    assert_nil Offer.new(kind: Offer::ROOM, room:, discount_percent: 15).discounted_price
  end

  test "discounted_price and original_price are nil for package offers" do
    offer = create_es(Offer, kind: Offer::PACKAGE, title: "Paquete", discount_percent: 20)
    assert_nil offer.original_price
    assert_nil offer.discounted_price
  end

  # --- display fallbacks -------------------------------------------------

  test "a room offer falls back to the room's title, description and badge" do
    room = create_es(Room, name: "Suite Colonial", description: "Vista al jardín")
    offer = create_es(Offer, kind: Offer::ROOM, room:, discount_percent: 25)

    Mobility.with_locale(:es) do
      assert_equal "Suite Colonial", offer.display_title
      assert_equal "Vista al jardín", offer.display_description
      assert_equal "25% DESCUENTO", offer.display_badge
    end
  end

  test "an offer's own title, description and badge win over the room's" do
    room = create_es(Room, name: "Suite Colonial", description: "Vista al jardín")
    offer = create_es(Offer, kind: Offer::ROOM, room:, discount_percent: 25,
                             title: "Oferta especial", description: "Incluye desayuno", badge: "ÚLTIMAS")

    Mobility.with_locale(:es) do
      assert_equal "Oferta especial", offer.display_title
      assert_equal "Incluye desayuno", offer.display_description
      assert_equal "ÚLTIMAS", offer.display_badge
    end
  end

  test "ticker_text prefers its own text, then the description, then the discount" do
    room = create_es(Room, name: "Suite Colonial")
    offer = create_es(Offer, kind: Offer::ROOM, room:, discount_percent: 30)

    Mobility.with_locale(:es) do
      assert_equal "30% de descuento", offer.ticker_text

      offer.update!(description: "Incluye desayuno")
      assert_equal "Incluye desayuno", offer.ticker_text

      offer.update!(ticker_description: "¡Solo esta semana!")
      assert_equal "¡Solo esta semana!", offer.ticker_text
    end
  end

  # --- lifecycle & scopes ------------------------------------------------

  test "expired, scheduled and live reflect the validity window" do
    live = create_es(Offer, kind: Offer::PACKAGE, title: "Ahora",
                            valid_from: Date.current - 1, valid_until: Date.current + 1)
    expired = create_es(Offer, kind: Offer::PACKAGE, title: "Ayer", valid_until: Date.current - 1)
    scheduled = create_es(Offer, kind: Offer::PACKAGE, title: "Mañana", valid_from: Date.current + 1)

    assert live.live?
    assert_not live.expired?
    assert_not live.scheduled?

    assert expired.expired?
    assert_not expired.live?

    assert scheduled.scheduled?
    assert_not scheduled.live?
  end

  test "an inactive offer is never live" do
    offer = create_es(Offer, kind: Offer::PACKAGE, title: "x", active: false)
    assert_not offer.live?
  end

  test "visible skips inactive, expired and not-yet-started offers" do
    shown = create_es(Offer, kind: Offer::PACKAGE, title: "Visible")
    create_es(Offer, kind: Offer::PACKAGE, title: "Apagada", active: false)
    create_es(Offer, kind: Offer::PACKAGE, title: "Vencida", valid_until: Date.current - 1)
    create_es(Offer, kind: Offer::PACKAGE, title: "Futura", valid_from: Date.current + 1)

    assert_equal [ shown.id ], Offer.visible.pluck(:id)
  end

  test "visible skips a room offer whose room was deleted" do
    room = create_es(Room, name: "Suite Colonial")
    offer = create_es(Offer, kind: Offer::ROOM, room:, discount_percent: 10)
    assert_includes Offer.visible.pluck(:id), offer.id

    # `dependent: :destroy` takes the offer with it, but a row orphaned some
    # other way (a raw delete, a restore) must not reach the public page.
    offer.update_columns(room_id: nil)
    assert_not_includes Offer.visible.pluck(:id), offer.id
  end

  test "on_ticker returns only visible offers flagged for the ticker" do
    ticking = create_es(Offer, kind: Offer::PACKAGE, title: "En ticker", show_on_ticker: true)
    create_es(Offer, kind: Offer::PACKAGE, title: "Fuera del ticker")
    create_es(Offer, kind: Offer::PACKAGE, title: "Apagada", show_on_ticker: true, active: false)

    assert_equal [ ticking.id ], Offer.on_ticker.pluck(:id)
  end

  test "ordered sorts by position then id" do
    third = create_es(Offer, kind: Offer::PACKAGE, title: "c", position: 2)
    first = create_es(Offer, kind: Offer::PACKAGE, title: "a", position: 1)
    second = create_es(Offer, kind: Offer::PACKAGE, title: "b", position: 1)

    assert_equal [ first.id, second.id, third.id ], Offer.ordered.pluck(:id)
  end

  # --- validity_label ----------------------------------------------------

  test "validity_label covers both ends, one end, and neither" do
    from = Date.new(2026, 9, 1)
    upto = Date.new(2026, 9, 30)

    I18n.with_locale(:es) do
      assert_equal "Del 01/09/2026 al 30/09/2026",
        Offer.new(valid_from: from, valid_until: upto).validity_label
      assert_equal "A partir del 01/09/2026", Offer.new(valid_from: from).validity_label
      assert_equal "Válida hasta el 30/09/2026", Offer.new(valid_until: upto).validity_label
      assert_nil Offer.new.validity_label
    end
  end
end
