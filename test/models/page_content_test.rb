require "test_helper"

class PageContentTest < ActiveSupport::TestCase
  test "content is translated per locale but the key and title are not" do
    content = create_es(PageContent, key: "home_hero_title", title: "Título de portada",
                                     content: "Hotel Mesón del Bosque")
    Mobility.with_locale(:en) { content.update!(content: "Meson del Bosque Hotel") }

    Mobility.with_locale(:es) { assert_equal "Hotel Mesón del Bosque", content.reload.content }
    Mobility.with_locale(:en) { assert_equal "Meson del Bosque Hotel", content.reload.content }

    # `key` is how the templates look the record up and `title` is an
    # admin-panel-only label, so neither may vary by locale.
    I18n.with_locale(:en) do
      assert_equal "home_hero_title", content.reload.key
      assert_equal "Título de portada", content.title
    end
  end

  test "the CTA button switches all default to on" do
    content = PageContent.create!(key: "global")

    assert content.show_cta_call
    assert content.show_cta_whatsapp
    assert content.show_cta_email
  end

  test "brand assets attach independently of each other" do
    content = PageContent.create!(key: "global")
    content.logo.attach(**image_upload(filename: "logo.png"))
    content.favicon.attach(**image_upload(filename: "favicon.png"))

    assert content.logo.attached?
    assert content.favicon.attached?
    assert_not content.app_icon.attached?
  end
end
