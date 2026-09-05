require "test_helper"

class ExperienceTest < ActiveSupport::TestCase
  test "title and description are translated per locale" do
    experience = create_es(Experience, title: "Desayuno artesanal", description: "Pan recién horneado")
    Mobility.with_locale(:en) { experience.update!(title: "Artisan breakfast") }

    Mobility.with_locale(:es) { assert_equal "Desayuno artesanal", experience.reload.title }
    Mobility.with_locale(:en) do
      assert_equal "Artisan breakfast", experience.reload.title
      assert_equal "Pan recién horneado", experience.description, "untranslated text falls back to Spanish"
    end
  end

  test "an icon image can be attached" do
    experience = create_es(Experience, title: "Desayuno")
    experience.icon_image.attach(**image_upload)

    assert experience.icon_image.attached?
  end
end
