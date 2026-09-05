require "test_helper"

class HeroImageTest < ActiveSupport::TestCase
  test "an image can be attached and replaced" do
    hero = HeroImage.create!
    assert_not hero.image.attached?

    hero.image.attach(**image_upload(filename: "portada.png"))
    assert hero.image.attached?
    assert_equal "portada.png", hero.image.filename.to_s

    hero.image.attach(**image_upload(filename: "portada-nueva.png"))
    assert_equal "portada-nueva.png", hero.reload.image.filename.to_s
  end
end
