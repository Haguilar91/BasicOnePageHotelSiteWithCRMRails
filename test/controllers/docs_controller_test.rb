require "test_helper"

class DocsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_admin
    post user_session_path, params: { user: { email: @admin.email, password: "password123" } }
  end

  # The guide is a pair of long hand-written partials full of image_tag calls
  # and in-page anchors; both break loudly in production and silently in
  # development, so they're worth an actual render.
  test "the guide renders in both languages" do
    { "es" => "Guía del sitio", "en" => "Site Guide" }.each do |lang, title|
      get docs_path(lang:)
      assert_response :success
      assert_select "title", title
      assert_select "h2#telefonos, h2#phones", 1, "the phone setup section should be there"
    end
  end

  test "every table-of-contents link points at a section that exists" do
    %w[es en].each do |lang|
      get docs_path(lang:)
      ids = css_select("[id]").map { |node| node["id"] }
      css_select("nav.toc a").each do |link|
        anchor = link["href"].delete_prefix("#")
        assert_includes ids, anchor, "#{lang}: the guide links to ##{anchor}, which no section defines"
      end
    end
  end

  # Deliberately open to any signed-in account, not just admins: it's
  # read-only reference material for staff, not an editing surface. Only the
  # route-level `authenticate :user` gate applies.
  test "any signed-in member of staff can read the guide" do
    delete destroy_user_session_path
    post user_session_path,
      params: { user: { email: create_user(email: "plain@example.com").email, password: "password123" } }

    get docs_path
    assert_response :success
  end

  test "the guide is closed to signed-out visitors" do
    delete destroy_user_session_path
    get docs_path
    assert_redirected_to new_user_session_path
  end
end
