class Offer < ApplicationRecord
  extend Mobility
  translates :title, :badge, backend: :key_value, type: :string
  translates :description, :ticker_description, backend: :key_value, type: :text

  ROOM = "room".freeze
  PACKAGE = "package".freeze
  KINDS = {
    ROOM => "Oferta de Habitación",
    PACKAGE => "Paquete"
  }.freeze

  # Splits a free-form room price ("Desde $150", "$700.00 MXN") into the text
  # around the amount and the amount itself, so a discounted price can be
  # rendered back in whatever format the admin typed.
  PRICE_PATTERN = /\A(?<prefix>\D*)(?<amount>[\d.,]*\d)(?<suffix>.*)\z/m

  has_one_attached :photo
  belongs_to :room, optional: true

  validates :kind, inclusion: { in: KINDS.keys }
  validates :title, presence: true, unless: :room_offer?
  validates :room, presence: true, if: :room_offer?
  validates :discount_percent,
    presence: true,
    numericality: { only_integer: true, greater_than: 0, less_than: 100 },
    if: :room_offer?
  validate :valid_until_after_valid_from

  scope :ordered, -> { order(:position, :id) }
  scope :visible, -> {
    where(active: true)
      .where("valid_from IS NULL OR valid_from <= ?", Date.current)
      .where("valid_until IS NULL OR valid_until >= ?", Date.current)
      .where("kind != ? OR room_id IS NOT NULL", ROOM)
  }
  scope :on_ticker, -> { visible.where(show_on_ticker: true) }
  scope :room_kind, -> { where(kind: ROOM) }

  def room_offer? = kind == ROOM
  def package_offer? = kind == PACKAGE

  def display_title
    title.presence || room&.name
  end

  # The pre-discount price, shown struck through on room offers.
  def original_price
    room&.price if room_offer?
  end

  # Room price with the discount applied, keeping the room's own formatting.
  # Returns nil when the room price has no parsable amount (e.g. "Consultar").
  def discounted_price
    return nil unless room_offer? && discount_percent.present?

    match = PRICE_PATTERN.match(original_price.to_s)
    return nil if match.nil?

    amount = match[:amount].delete(",").to_d
    return nil if amount.zero?

    discounted = amount * (100 - discount_percent) / 100
    "#{match[:prefix]}#{format_like(discounted, match[:amount])}#{match[:suffix]}"
  end

  # Room offers fall back to the room's own badge slot and photo, so an admin
  # only has to fill in the room and the discount.
  def display_badge
    return badge if badge.present?

    I18n.t("models.offer.discount_badge", percent: discount_percent) if room_offer? && discount_percent.present?
  end

  def display_photo
    return photo if photo.attached?

    room.photo if room_offer? && room&.photo&.attached?
  end

  def display_description
    description.presence || (room&.description if room_offer?)
  end

  def ticker_text
    return ticker_description if ticker_description.present?
    return display_description if display_description.present?

    I18n.t("models.offer.discount_ticker", percent: discount_percent) if room_offer? && discount_percent.present?
  end

  def expired?
    valid_until.present? && valid_until < Date.current
  end

  # Active and saved, but its start date hasn't arrived yet.
  def scheduled?
    valid_from.present? && valid_from > Date.current
  end

  def live?
    active? && !scheduled? && !expired?
  end

  # "Del 01/09/2026 al 30/09/2026", or one-sided when only one date is set.
  def validity_label
    from = valid_from&.strftime("%d/%m/%Y")
    upto = valid_until&.strftime("%d/%m/%Y")

    if from && upto
      I18n.t("models.offer.validity.range", from:, upto:)
    elsif from
      I18n.t("models.offer.validity.from_only", from:)
    elsif upto
      I18n.t("models.offer.validity.until_only", upto:)
    end
  end

  private

  def valid_until_after_valid_from
    return if valid_from.blank? || valid_until.blank?
    return if valid_until >= valid_from

    errors.add(:valid_until, I18n.t("models.offer.errors.valid_until_before_valid_from"))
  end

  # Mirrors the decimal precision the admin used, so "150" stays "127" and
  # "700.00" stays "595.00".
  def format_like(value, original_amount)
    decimals = original_amount.include?(".") ? original_amount.split(".").last.length : 0
    number = value.round(decimals)
    formatted = decimals.zero? ? number.to_i.to_s : format("%.#{decimals}f", number)
    original_amount.include?(",") ? formatted.gsub(/\B(?=(\d{3})+(?!\d))/, ",") : formatted
  end
end
