class ApplicationController < ActionController::Base
  # `allow_browser versions: :modern` used to guard every page here, but it
  # answers 406 to anything older than Safari 17.2 / Chrome 120 — including
  # phones guests actually book from, and with an unstyled error page. This is
  # a public hotel site that uses no import maps, web push or badges, so the
  # guard costs real bookings and buys nothing.

  around_action :switch_locale

  private

  # `I18n.with_locale` (block form), not `I18n.locale =` — Puma runs
  # threaded, so a bare assignment isn't safely scoped to this request alone.
  def switch_locale(&action)
    locale = params[:locale].presence&.to_sym
    if locale && !I18n.available_locales.include?(locale)
      raise ActionController::RoutingError, "Unknown locale: #{locale}"
    end

    I18n.with_locale(locale || I18n.default_locale, &action)
  end

  # Makes route helpers (root_path, link_to, etc.) automatically carry the
  # current locale, so internal links don't need `locale:` passed explicitly.
  # Omitted for the default locale so Spanish URLs stay bare ("/") rather
  # than "/es/" everywhere.
  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
