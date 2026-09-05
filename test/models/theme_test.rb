require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  def build_colors
    Theme::COLOR_ATTRIBUTES.index_with { "#d4af37" }
  end

  test "every colour must be a six-digit hex value" do
    assert Theme.new(name: "Dorado", **build_colors).valid?

    theme = Theme.new(name: "Dorado", **build_colors.merge("accent" => "dorado"))
    assert_not theme.valid?
    assert_includes theme.errors.attribute_names, :accent
  end

  test "a three-digit hex shorthand is rejected" do
    # CSS accepts #fff, the layout interpolates these straight into a
    # <style> block, but the admin form asks for the long form — so the
    # validation has to actually hold that line.
    assert_not Theme.new(name: "Dorado", **build_colors.merge("accent" => "#fff")).valid?
  end

  test "the slug is generated from the name on create" do
    theme = Theme.create!(name: "Dorado Colonial", **build_colors)
    assert_equal "dorado-colonial", theme.slug
  end

  test "an explicit slug is left alone" do
    theme = Theme.create!(name: "Dorado Colonial", slug: "clasico", **build_colors)
    assert_equal "clasico", theme.slug
  end

  test "slugs are unique" do
    Theme.create!(name: "Dorado Colonial", **build_colors)
    assert_not Theme.new(name: "Dorado Colonial", **build_colors).valid?
  end

  test "activating a theme deactivates every other one" do
    first = Theme.create!(name: "Uno", active: true, **build_colors)
    second = Theme.create!(name: "Dos", active: true, **build_colors)

    assert_not first.reload.active
    assert second.reload.active
  end

  test "saving the already-active theme keeps it active" do
    theme = Theme.create!(name: "Uno", active: true, **build_colors)
    theme.update!(name: "Uno renombrado")

    assert theme.reload.active
  end

  test "current returns the active theme" do
    Theme.create!(name: "Inactivo", **build_colors)
    active = Theme.create!(name: "Activo", active: true, **build_colors)

    assert_equal active, Theme.current
  end

  test "current falls back to a built-in palette when nothing is active" do
    Theme.create!(name: "Inactivo", **build_colors)

    assert_equal Theme::FALLBACK, Theme.current
    # The layout reads these straight off whatever current returns, so the
    # fallback has to answer every colour the real model does.
    Theme::COLOR_ATTRIBUTES.each do |attribute|
      assert_match Theme::HEX_FORMAT, Theme.current.public_send(attribute)
    end
  end
end
