# frozen_string_literal: true

class Pagy
  private

  def nav_aria_label_attribute(aria_label: nil)
    aria_label ||= I18n.translate('pagy.aria_label.nav', count: @last)
    %(aria-label="#{aria_label}")
  end
end
