# The hotel's phone lines. Supersedes the single `contact_phone` PageContent
# value: one number can be flagged as the WhatsApp line, another as the line
# the "Llamar ahora" button dials, and any number (including those two) can
# be listed in the public contact section.
#
# Everything falls back gracefully when the table is empty — see
# ApplicationHelper#whatsapp_phone_number / #call_phone_number, which drop
# back to the old `contact_phone` key so the site keeps working before an
# admin has entered anything here.
class PhoneNumber < ApplicationRecord
  extend Mobility
  translates :label, backend: :key_value, type: :string

  validates :number, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :listed, -> { where(visible: true).ordered }

  # Exactly-one semantics for the two roles: checking the box on a new row
  # clears it everywhere else, the same way Theme#active works.
  before_save :clear_other_whatsapp, if: -> { whatsapp_active? && whatsapp_active_changed? }
  before_save :clear_other_call, if: -> { call_active? && call_active_changed? }

  def self.whatsapp_line
    find_by(whatsapp_active: true) || ordered.first
  end

  def self.call_line
    find_by(call_active: true) || ordered.first
  end

  # Digits only, for wa.me URLs (which reject "+", spaces and punctuation).
  def self.digits(number)
    number.to_s.gsub(/\D/, "")
  end

  # Keeps a leading "+" so tel: links dial internationally.
  def self.dialable(number)
    number.to_s.gsub(/[^\d+]/, "")
  end

  def digits = self.class.digits(number)
  def dialable = self.class.dialable(number)

  private

  def clear_other_whatsapp
    PhoneNumber.where.not(id: id).update_all(whatsapp_active: false)
  end

  def clear_other_call
    PhoneNumber.where.not(id: id).update_all(call_active: false)
  end
end
