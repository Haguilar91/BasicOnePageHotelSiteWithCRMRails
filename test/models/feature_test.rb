require "test_helper"

class FeatureTest < ActiveSupport::TestCase
  test "title and description are translated per locale" do
    feature = create_es(Feature, title: "Wi-Fi gratis", description: "En todo el hotel")
    Mobility.with_locale(:en) { feature.update!(title: "Free Wi-Fi", description: "Throughout the hotel") }

    Mobility.with_locale(:es) do
      assert_equal "Wi-Fi gratis", feature.reload.title
      assert_equal "En todo el hotel", feature.description
    end
    Mobility.with_locale(:en) do
      assert_equal "Free Wi-Fi", feature.reload.title
      assert_equal "Throughout the hotel", feature.description
    end
  end
end
