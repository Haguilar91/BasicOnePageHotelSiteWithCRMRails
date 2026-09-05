require "test_helper"

class TranslationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  test "the panel lists every registered model with its Spanish source text" do
    create_es(Room, name: "Suite Colonial")
    create_es(PhoneNumber, number: "+52 1", label: "Recepción")

    get translations_path
    assert_response :success
    assert_match "Suite Colonial", response.body
    assert_match "Recepción", response.body
    assert_match "Habitaciones", response.body
    assert_match "Teléfonos", response.body
  end

  test "saving writes English without touching the Spanish source" do
    room = create_es(Room, name: "Suite Colonial", description: "Vista al jardín")

    patch translations_path, params: {
      translations: { "room" => { room.id.to_s => { "name" => "Colonial Suite" } } }
    }
    assert_redirected_to translations_path

    Mobility.with_locale(:en) { assert_equal "Colonial Suite", room.reload.name }
    Mobility.with_locale(:es) do
      assert_equal "Suite Colonial", room.reload.name
      assert_equal "Vista al jardín", room.description, "a field left out of the form is untouched"
    end
  end

  test "one submit saves across several models at once" do
    room = create_es(Room, name: "Suite Colonial")
    feature = create_es(Feature, title: "Wi-Fi gratis")

    patch translations_path, params: {
      translations: {
        "room" => { room.id.to_s => { "name" => "Colonial Suite" } },
        "feature" => { feature.id.to_s => { "title" => "Free Wi-Fi" } }
      }
    }

    Mobility.with_locale(:en) do
      assert_equal "Colonial Suite", room.reload.name
      assert_equal "Free Wi-Fi", feature.reload.title
    end
  end

  test "a record that is invalid in Spanish can still be translated" do
    # Announcement validates presence on title/description, and the panel
    # saves with validate: false precisely so a half-finished record
    # elsewhere can't block an unrelated translation from being saved.
    announcement = create_es(Announcement, title: "Aviso", description: "Texto",
                                           start_date: Date.current, end_date: Date.current + 1, active: true)
    announcement.update_columns(start_date: nil)

    patch translations_path, params: {
      translations: { "announcement" => { announcement.id.to_s => { "title" => "Notice" } } }
    }
    assert_redirected_to translations_path

    Mobility.with_locale(:en) { assert_equal "Notice", announcement.reload.title }
  end

  test "an unknown record id is skipped rather than raising" do
    patch translations_path, params: {
      translations: { "room" => { "999999" => { "name" => "Nope" } } }
    }
    assert_redirected_to translations_path
  end

  test "the panel is closed to non-admins and to visitors" do
    delete destroy_user_session_path
    post user_session_path, params: { user: { email: create_user(email: "plain@example.com").email, password: "password123" } }
    get translations_path
    assert_redirected_to root_path

    delete destroy_user_session_path
    get translations_path
    assert_redirected_to new_user_session_path
  end
end
