class Room < ApplicationRecord
  extend Mobility
  translates :name, :badge, :button_name, :price, backend: :key_value, type: :string
  translates :description, :features, backend: :key_value, type: :text

  # `photo` is kept for rooms created before the gallery existed; `photos` is
  # the current multi-image gallery. See #gallery_photos for how they combine.
  has_one_attached :photo
  has_many_attached :photos

  # A room offer is defined by its room, so it goes away with it.
  has_many :offers, dependent: :destroy

  BOOKING_PLATFORMS = {
    "custom" => { label: "Personalizado", icon: "fa-solid fa-calendar-check", default_button_name: "Reservar" },
    "airbnb" => { label: "Airbnb", icon: "fa-brands fa-airbnb", default_button_name: "Reservar en Airbnb" },
    "whatsapp" => { label: "WhatsApp", icon: "fa-brands fa-whatsapp", default_button_name: "Reservar por WhatsApp" },
    "booking" => { label: "Booking.com", icon: "fa-solid fa-hotel", default_button_name: "Reservar en Booking.com" }
  }.freeze

  validates :booking_platform, inclusion: { in: BOOKING_PLATFORMS.keys }

  def booking_button_icon
    platform_meta[:icon]
  end

  # Uses I18n rather than BOOKING_PLATFORMS[:default_button_name] directly so
  # the public button label follows the site's current locale — the hash's
  # own :label/:default_button_name stay Spanish-only for the Avo admin
  # select field, which always renders in Spanish (config.locale = :es).
  def booking_button_label
    button_name.presence || platform_meta[:default_button_name]
  end

  # Photos to show in the room card/gallery, newest UI first: the `photos`
  # collection if any were uploaded, falling back to the legacy single
  # `photo` so rooms set up before the gallery existed keep working.
  def gallery_photos
    photos.attached? ? photos : (photo.attached? ? [photo] : [])
  end

  private

  def platform_meta
    key = BOOKING_PLATFORMS.key?(booking_platform) ? booking_platform : "custom"
    {
      icon: BOOKING_PLATFORMS.dig(key, :icon),
      label: I18n.t("models.room.booking_platforms.#{key}.label"),
      default_button_name: I18n.t("models.room.booking_platforms.#{key}.default_button_name")
    }
  end
end
