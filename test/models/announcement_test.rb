require "test_helper"

class AnnouncementTest < ActiveSupport::TestCase
  def valid_attributes(**overrides)
    { title: "Cerrado por mantenimiento", description: "Del 1 al 5 de octubre",
      start_date: Date.current, end_date: Date.current + 5, active: true }.merge(overrides)
  end

  test "title, description, both dates and the active flag are required" do
    assert create_es(Announcement, **valid_attributes).valid?

    %i[title description start_date end_date active].each do |attribute|
      announcement = Announcement.new(valid_attributes(attribute => nil))
      assert_not announcement.valid?, "#{attribute} should be required"
      assert_includes announcement.errors.attribute_names, attribute
    end
  end

  test "active: false is a valid value, not a missing one" do
    assert Announcement.new(valid_attributes(active: false)).valid?
  end

  test "title and description are translated per locale" do
    announcement = create_es(Announcement, **valid_attributes)
    Mobility.with_locale(:en) { announcement.update!(title: "Closed for maintenance") }

    Mobility.with_locale(:es) { assert_equal "Cerrado por mantenimiento", announcement.reload.title }
    Mobility.with_locale(:en) { assert_equal "Closed for maintenance", announcement.reload.title }
  end
end
