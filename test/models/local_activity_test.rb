require "test_helper"

class LocalActivityTest < ActiveSupport::TestCase
  def valid_attributes(**overrides)
    { title: "La Mariposa", category: "Restaurantes", description: "Cafetería histórica",
      google_maps_url: "https://maps.google.com/?q=la+mariposa" }.merge(overrides)
  end

  # Regression: `title`/`description` moved into Mobility's translation tables
  # but their old columns kept a NOT NULL constraint, so every create failed
  # with "NOT NULL constraint failed: local_activities.title_legacy" even
  # with a fully filled-in form.
  test "an activity can be created even though the legacy columns stay empty" do
    activity = LocalActivity.new(valid_attributes)

    assert activity.save, activity.errors.full_messages.join(", ")
    assert_nil activity.reload.title_legacy
    assert_nil activity.description_legacy
    Mobility.with_locale(:es) { assert_equal "La Mariposa", activity.title }
  end

  test "title, category, description and the maps link are all required" do
    %i[title category description google_maps_url].each do |attribute|
      activity = LocalActivity.new(valid_attributes(attribute => nil))
      assert_not activity.valid?, "#{attribute} should be required"
      assert_includes activity.errors.attribute_names, attribute
    end
  end

  test "the category must be one of the three known ones" do
    assert_not LocalActivity.new(valid_attributes(category: "Bares")).valid?

    LocalActivity::CATEGORIES.each do |category|
      assert LocalActivity.new(valid_attributes(category:)).valid?, "#{category} should be accepted"
    end
  end

  test "category_label translates the stored Spanish category" do
    I18n.with_locale(:en) { assert_equal "Restaurants", LocalActivity.category_label("Restaurantes") }
    I18n.with_locale(:es) { assert_equal "Restaurantes", LocalActivity.category_label("Restaurantes") }
  end

  test "category_label raises on an unknown category rather than rendering a blank tab" do
    assert_raises(KeyError) { LocalActivity.category_label("Bares") }
  end

  test "every known category has a label in both locales" do
    %i[es en].each do |locale|
      I18n.with_locale(locale) do
        LocalActivity::CATEGORIES.each do |category|
          assert LocalActivity.category_label(category).present?, "#{category} in #{locale}"
        end
      end
    end
  end
end
