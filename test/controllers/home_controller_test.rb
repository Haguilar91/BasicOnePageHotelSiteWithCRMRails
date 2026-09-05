require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "the homepage renders for a visitor with an empty database" do
    get root_path
    assert_response :success
  end

  test "the homepage renders with content in it" do
    room = create_es(Room, name: "Suite Colonial", price: "$1,200", description: "Vista al jardín")
    room.photos.attach(**image_upload)
    create_es(Offer, kind: Offer::ROOM, room:, discount_percent: 20, show_on_ticker: true)
    create_es(Experience, title: "Desayuno artesanal")
    create_es(Feature, title: "Wi-Fi gratis")
    create_es(LocalActivity, title: "La Mariposa", category: "Restaurantes",
                             description: "Cafetería histórica", google_maps_url: "https://maps.google.com/?q=x")
    create_es(GalleryPhoto, caption: "Terraza").photo.attach(**image_upload)

    get root_path
    assert_response :success
    assert_select "h3", text: /Suite Colonial/
    assert_select "#que-hacer"
  end

  test "the homepage renders in English" do
    create_es(Room, name: "Suite Colonial")

    get root_path(locale: :en)
    assert_response :success
    assert_select "html[lang=?]", "en"
  end

  test "home/index is reachable under both its routes" do
    get home_index_path
    assert_response :success
  end

  # The phone lines the CTA and contact section read come from PhoneNumber,
  # falling back to the legacy `contact_phone` value while that table is empty.
  test "the call button dials the flagged call line" do
    PhoneNumber.create!(number: "+52 442 111 1111", whatsapp_active: true)
    PhoneNumber.create!(number: "+52 442 222 2222", call_active: true, position: 1)

    get root_path
    assert_select "a[href=?]", "tel:+524422222222"
    assert_select "[data-phone=?]", "524421111111"
  end

  test "the phone falls back to contact_phone when no numbers are set up" do
    create_es(PageContent, key: "contact_phone", content: "+52 442 999 9999")

    get root_path
    assert_select "a[href=?]", "tel:+524429999999"
    assert_select "[data-phone=?]", "524429999999"
  end

  test "a visitor sees no Easy Edit markers" do
    get root_path
    assert_select "[data-easy-edit-trigger]", false
    assert_select ".easy-edit-banner", false
  end
end
