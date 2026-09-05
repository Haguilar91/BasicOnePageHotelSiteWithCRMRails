require "test_helper"

class GalleryPhotoTest < ActiveSupport::TestCase
  test "a photo can be attached and its caption is translated" do
    photo = create_es(GalleryPhoto, caption: "Terraza")
    photo.photo.attach(**image_upload(filename: "terraza.png"))

    assert photo.photo.attached?
    Mobility.with_locale(:es) { assert_equal "Terraza", photo.reload.caption }
  end

  test "position defaults to zero" do
    assert_equal 0, GalleryPhoto.create!.position
  end
end
