class Theme < ApplicationRecord
  HEX_FORMAT = /\A#[0-9a-fA-F]{6}\z/

  COLOR_ATTRIBUTES = %w[bg_primary bg_secondary bg_tertiary accent accent_soft text_muted].freeze

  # Readable text color to place on top of a given background hex — picked
  # as whichever of near-black or white gives the better WCAG contrast
  # ratio. Exists because the views used to hardcode `text-white`, which
  # broke the moment an admin picked a light theme (see COLOR_ATTRIBUTES
  # above: only backgrounds were theme-driven, never the text on top of
  # them).
  LIGHT_TEXT = "#ffffff"
  DARK_TEXT = "#0f172a"

  def self.contrasting_text_for(hex)
    r, g, b = hex[1..2].to_i(16), hex[3..4].to_i(16), hex[5..6].to_i(16)

    luminance = [r, g, b].map do |channel|
      c = channel / 255.0
      c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
    end.then { |rl, gl, bl| (0.2126 * rl) + (0.7152 * gl) + (0.0722 * bl) }

    contrast_with_white = 1.05 / (luminance + 0.05)
    contrast_with_black = (luminance + 0.05) / 0.05
    contrast_with_black >= contrast_with_white ? DARK_TEXT : LIGHT_TEXT
  end

  # Gives both the real (ActiveRecord) theme and the FALLBACK struct below
  # the same `text_on_*` readers, each deferring to the shared formula above.
  module ContrastingText
    def text_on_bg_primary
      Theme.contrasting_text_for(bg_primary)
    end

    def text_on_bg_secondary
      Theme.contrasting_text_for(bg_secondary)
    end

    def text_on_bg_tertiary
      Theme.contrasting_text_for(bg_tertiary)
    end

    def text_on_accent
      Theme.contrasting_text_for(accent)
    end
  end

  include ContrastingText

  # Used when no theme has been seeded yet, so the site never breaks.
  FallbackTheme = Struct.new(:name, *COLOR_ATTRIBUTES.map(&:to_sym), keyword_init: true) do
    include Theme::ContrastingText
  end
  FALLBACK = FallbackTheme.new(
    name: "Dorado Colonial",
    bg_primary: "#0f172a",
    bg_secondary: "#1e293b",
    bg_tertiary: "#334155",
    accent: "#d4af37",
    accent_soft: "#f4e4bc",
    text_muted: "#9ca3af"
  ).freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  COLOR_ATTRIBUTES.each do |attribute|
    validates attribute, presence: true, format: { with: HEX_FORMAT, message: "debe ser un color hexadecimal, ej. #d4af37" }
  end

  before_validation :generate_slug, on: :create

  scope :ordered, -> { order(:position, :id) }

  def self.current
    find_by(active: true) || FALLBACK
  end

  before_save :deactivate_others, if: -> { active? && active_changed? }

  private

  def generate_slug
    self.slug = name.to_s.parameterize if slug.blank? && name.present?
  end

  def deactivate_others
    Theme.where.not(id: id).update_all(active: false)
  end
end
