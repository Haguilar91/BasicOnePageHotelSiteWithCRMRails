class Theme < ApplicationRecord
  HEX_FORMAT = /\A#[0-9a-fA-F]{6}\z/

  COLOR_ATTRIBUTES = %w[bg_primary bg_secondary bg_tertiary accent accent_soft text_muted].freeze

  # Used when no theme has been seeded yet, so the site never breaks.
  FallbackTheme = Struct.new(:name, *COLOR_ATTRIBUTES.map(&:to_sym), keyword_init: true)
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
