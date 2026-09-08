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
  MUTED_ALPHA = 0.6

  # WCAG's floor for non-text UI components (icons, borders, focus rings).
  # Below this, accent-colored icons blend into whatever they sit on — see
  # the "accent == bg_primary" incident this validation exists to prevent.
  MIN_ACCENT_CONTRAST = 3.0

  def self.relative_luminance(hex)
    r, g, b = hex[1..2].to_i(16), hex[3..4].to_i(16), hex[5..6].to_i(16)

    [r, g, b].map do |channel|
      c = channel / 255.0
      c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
    end.then { |rl, gl, bl| (0.2126 * rl) + (0.7152 * gl) + (0.0722 * bl) }
  end

  def self.contrast_ratio(hex_a, hex_b)
    la, lb = relative_luminance(hex_a), relative_luminance(hex_b)
    la, lb = lb, la if lb > la
    (la + 0.05) / (lb + 0.05)
  end

  def self.contrasting_text_for(hex)
    contrast_ratio(hex, DARK_TEXT) >= contrast_ratio(hex, LIGHT_TEXT) ? DARK_TEXT : LIGHT_TEXT
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

    # A dimmed version of the contrast color rather than the admin-set
    # `text_muted` field: `text_muted` was designed assuming bg_primary is
    # always dark (see its Avo help text) and, like the old hardcoded
    # `text-white` classes, went unreadable the moment a light theme was
    # created. Using alpha instead of a flat hex also keeps it legible
    # whether it lands on bg_primary, bg_secondary, or bg_tertiary — the
    # same call site is used against all three.
    def muted_text_color
      if Theme.contrasting_text_for(bg_primary) == Theme::LIGHT_TEXT
        "rgba(255, 255, 255, #{Theme::MUTED_ALPHA})"
      else
        "rgba(15, 23, 42, #{Theme::MUTED_ALPHA})"
      end
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
  validate :accent_contrasts_with_backgrounds

  before_validation :generate_slug, on: :create

  scope :ordered, -> { order(:position, :id) }

  def self.current
    find_by(active: true) || FALLBACK
  end

  before_save :deactivate_others, if: -> { active? && active_changed? }

  BACKGROUND_LABELS = {
    "bg_primary" => "el fondo principal",
    "bg_secondary" => "el fondo secundario",
    "bg_tertiary" => "el fondo terciario"
  }.freeze

  private

  # Accent is used as `text-[var(--color-accent)]` for icons, checkmarks and
  # badges precisely so they pop against whichever background surrounds
  # them — so it has to hold up against all three, not just one.
  def accent_contrasts_with_backgrounds
    return unless accent.present? && HEX_FORMAT.match?(accent)

    BACKGROUND_LABELS.each do |attribute, label|
      background = public_send(attribute)
      next unless background.present? && HEX_FORMAT.match?(background)

      ratio = Theme.contrast_ratio(accent, background)
      next if ratio >= MIN_ACCENT_CONTRAST

      errors.add(:accent, "no contrasta lo suficiente con #{label} (#{ratio.round(1)}:1 — se necesita al menos #{MIN_ACCENT_CONTRAST.to_i}:1). Elige un acento más distinto.")
    end
  end

  def generate_slug
    self.slug = name.to_s.parameterize if slug.blank? && name.present?
  end

  def deactivate_others
    Theme.where.not(id: id).update_all(active: false)
  end
end
